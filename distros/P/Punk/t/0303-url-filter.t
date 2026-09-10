#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use Punk ();

# The template half of named routes: the `url_for` filter and the bound
# `url` hash.
#
# Two seams, because Stencil has two. A filter takes the value and one
# literal argument, so `{% row | url_for('book') %}` can carry captures; a
# hash costs a lookup inside the engine and no call boundary, so
# `{% url.books %}` is the cheaper spelling for the routes that need none.
#
# The `url` hash is TIED. A plain one would render `{% url.typo %}` as the
# empty string - Stencil's answer for a missing path - and `href=""` is a
# link to the current page that looks like it works. Measured cost of the
# tie: 280ns a lookup, 8.4us on a thirty-link page, about one file-cache
# hit. The assertion that a typo fails the render is below, and it is the
# whole reason for paying that.

my $TD = "$FindBin::Bin/test/urltmpl";

{
    package UT;
    use Punk;
    host 'https://example.com';
    views Stencil => { template_dir => $TD };

    get '/books'           => \&main::ok_, { name => 'books' };
    get '/books/:id'       => \&main::ok_, { name => 'book'  };
    get '/b/:id/tags/:tag' => \&main::ok_, { name => 'tag'   };

    get '/links' => sub {
        $_[0]->render('links', { id => 42, row => { id => 7 } });
    }, { name => 'links' };
    get '/typo'  => sub { $_[0]->render('typo') },  { name => 'typo_p' };
    get '/dyn'   => sub { $_[0]->render('dyn') },   { name => 'dyn_p'  };
    get '/two'   => sub { $_[0]->render('two', { id => 1 }) }, { name => 'two_p' };
    get '/enc'   => sub {
        $_[0]->render('cap', { id => "caf\x{e9}" });
    }, { name => 'enc_p' };
    get '/qs'    => sub {
        $_[0]->render('qs', { row => { id => 5, page => 2, q => 'a b' } });
    }, { name => 'qs_p' };

    # a data hashref the handler keeps between requests - the shape that
    # makes set-if-absent a bug
    our $KEPT = {};
    get '/kept' => sub { $_[0]->render('one', $KEPT) }, { name => 'kept' };
}

sub ok_ { $_[0]->text('ok') }

my $app = UT->to_app;
sub body { my $r = shift; return join '', @{ $r->[2] || [] } }

# ---- the two forms --------------------------------------------------------

{
    my $res = hit($app, path => '/links');
    is $res->[0], 200, 'a page using both forms renders';
    my $b = body($res);
    like $b, qr{^static:/books$}m,     'the url hash gives a static route';
    like $b, qr{^scalar:/books/42$}m,
        'a scalar value fills the route\'s one capture';
    like $b, qr{^hash:/books/7$}m,
        'a hashref fills captures by name - a model row, usually';
}

{
    # Auto-escaping runs AFTER the last filter, so the '&' joining two query
    # pairs reaches the page as '&amp;'. That is correct inside an href and
    # is what a hand-written template would have had to do; the filter must
    # NOT mark its output escaped to avoid it.
    my $res = hit($app, path => '/qs');
    like body($res), qr{^/books/5\?page=2&amp;q=a%20b$}m,
        'a key in the hashref that names no capture is a query pair';

    # ... and what a browser reads back out of that href is the URL
    my ($href) = body($res) =~ m{^(\S+)$}m;
    (my $decoded = $href) =~ s/&amp;/&/g;
    is $decoded, '/books/5?page=2&q=a%20b',
        'and unescaping the attribute gives the URL url_for built';
}

# ---- the croaks are render errors, not empty strings ----------------------

{
    my $res = hit($app, path => '/typo');
    isnt $res->[0], 200, 'a misspelled name in the url hash fails the render';
    like body($res) . ($res->[0] // ''), qr/nosuch/,
        'and the failure names the name that is not there';
}

{
    my $res = hit($app, path => '/dyn');
    isnt $res->[0], 200,
        'a route that captures is not in the url hash';
    like body($res), qr/use the filter/,
        'and the message says which form does take captures';
}

{
    my $res = hit($app, path => '/two');
    isnt $res->[0], 200,
        'a scalar value on a two-capture route fails rather than guessing';
    like body($res), qr/2 captures/, 'and says how many it wanted';
}

# ---- encoding through the filter ------------------------------------------

{
    # The filter runs BEFORE Stencil's auto-escaping, and its output is a
    # URL: the bytes must be UTF-8 percent-encoding, and must not then be
    # escaped a second time into %C3%83%C2%A9.
    my $res = hit($app, path => '/enc');
    like body($res), qr{^/books/caf%C3%A9$}m,
        'a non-ASCII capture is UTF-8 percent-encoded exactly once';
    unlike body($res), qr/%C3%83/,
        'and not double-encoded on its way through the template';
}

# ---- the prefix reaches a filter that cannot see the context --------------

{
    my $res = hit($app, path => '/links', env => { SCRIPT_NAME => '/mnt' });
    my $b = body($res);
    like $b, qr{^static:/mnt/books$}m,  'the url hash carries SCRIPT_NAME';
    like $b, qr{^scalar:/mnt/books/42$}m,
        'and so does the filter, which has no request of its own';
}

{
    # a path on `host`: configuration, not the request
    {
        package UTP;
        use Punk;
        host 'https://example.com/site';
        views Stencil => { template_dir => $TD };
        get '/books' => \&main::ok_, { name => 'books' };
        get '/one'   => sub { $_[0]->render('one') }, { name => 'one' };
    }
    my $pa = UTP->to_app;
    like body(hit($pa, path => '/one')), qr{^/site/books$}m,
        'the path on `host` reaches a template too';
    like body(hit($pa, path => '/one', env => { SCRIPT_NAME => '/mnt' })),
        qr{^/site/mnt/books$}m,
        'and layers with SCRIPT_NAME in the same order url_for uses';
}

# ---- SET, not set-if-absent -----------------------------------------------

{
    # the handler renders with one hashref it keeps between requests; if the
    # binder only filled an absent key, the second request would serve the
    # first one's prefix, and a page in the wrong prefix still looks like a
    # page
    my $a = body(hit($app, path => '/kept', env => { SCRIPT_NAME => '/one' }));
    my $b = body(hit($app, path => '/kept', env => { SCRIPT_NAME => '/two' }));
    like $a, qr{^/one/books$}m, 'the first request gets its own prefix';
    like $b, qr{^/two/books$}m,
        'and a kept data hashref does not freeze the first one in';
}

{
    # ... and the prefix the FILTER reads is put back after the render, so a
    # render outside a request - a mail template from a queue job - does not
    # inherit whatever page this worker served last
    hit($app, path => '/links', env => { SCRIPT_NAME => '/mnt' });
    my $views = UT->punk_app->{views_compiled};
    my $res = $views->render(undef, 'links', { id => 42, row => { id => 7 } });
    my $b = join '', @{ $res->[2] };
    like $b, qr{^scalar:/books/42$}m,
        'a render with no context builds on no prefix, not the last one';
    unlike $b, qr{/mnt/},
        'the prefix slot did not survive the request that set it';
}

# ---- the application's own filter wins ------------------------------------

{
    # `filters` is the application's hash, and Punk adds to it only where it
    # left a gap - the rule `asset` already follows. Two built-ins with two
    # collision rules would be one rule too many.
    {
        package UTM;
        use Punk;
        views Stencil => {
            template_dir => $TD,
            filters      => { url_for => sub { "MINE:$_[0]" } },
        };
        get '/books/:id' => \&main::ok_, { name => 'book' };
        get '/mine' => sub { $_[0]->render('cap', { id => 9 }) },
            { name => 'mine' };
    }
    my $ma = UTM->to_app;
    my $res = hit($ma, path => '/mine');
    is $res->[0], 200, 'an application may register its own url_for filter';
    like body($res), qr/MINE:9/,
        'and it is the one that runs - Punk does not overwrite it';
}

# ---- an application that names nothing ------------------------------------

{
    {
        package UTN;
        use Punk;
        views Stencil => { template_dir => $TD };
        get '/x' => \&main::ok_;
        get '/one' => sub { $_[0]->render('one') }, { name => 'one' };
    }
    my $na = UTN->to_app;
    my $res = hit($na, path => '/one');
    isnt $res->[0], 200,
        'naming nothing and then asking for a name is still an error';
    like body($res), qr/no route is named 'books'/,
        'named as the name it could not find';
}

done_testing;
