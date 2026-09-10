#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use Punk ();

# $c->url_for: a path from a name, built over the segments punk_route.h
# parsed at to_app.
#
# The claim being tested is not "it returns a string" - it is that the
# string ROUTES BACK. A URL builder that disagrees with the matcher is worse
# than no builder, because every link it writes 404s in production and
# nowhere else. So the centre of this file is the round trip: for a table
# mixing every route kind, what url_for builds, Punk::Router->match resolves
# to the same record with the same captures.

# The application under test. One host, so `absolute` has something to
# build on, and one route of every shape.
{
    package UF;
    use Punk;
    host 'https://example.com', allow => [ 'shop.example.com' ];

    get '/books'              => \&main::show, { name => 'books' };
    get '/books/:id'          => \&main::show, { name => 'book'  };
    get '/b/:id/tags/:tag'    => \&main::show, { name => 'tag'   };
    get '/files/*path'        => \&main::show, { name => 'file'  };
    get '/'                   => \&main::show, { name => 'home'  };
    post '/books'             => \&main::show, { name => 'book_new' };
    my $admin = under '/admin';
    $admin->get('/books' => \&main::show, { name => 'admin_books' });

    # the route under test drives url_for from inside a request, which is
    # where it lives: it needs the context for the prefix and the origin
    get '/u' => \&main::build, { name => 'u' };
    get '/redir' => sub {
        my $c = shift;
        $c->redirect($c->url_for('book', id => 7));
    }, { name => 'redir' };
}

sub show { $_[0]->text('ok') }

# /u?call=<perl> evaluates one url_for call and returns it, or the croak.
# Driving it from inside a real request is the point: a prefix and an origin
# are request facts, and a builder tested outside one proves nothing about
# either.
our @CALL;
sub build {
    my ($c) = @_;
    my @out;
    for my $spec (@CALL) {
        my $got = eval { $c->url_for(@$spec) };
        my $err = $@;
        $err =~ s/\s+/ /g;
        push @out, defined $got ? $got : "ERR: $err";
    }
    return $c->text(join "\n", @out);
}

my $app = UF->to_app;

# Run the calls in @CALL through a request and give back one result each.
sub urls {
    local @CALL = @_;
    my $res = hit($app, path => '/u');
    my @lines = split /\n/, join '', @{ $res->[2] };
    return @lines;
}

# ... and the same under a PSGI mount or a proxy prefix
sub urls_env {
    my ($env, @calls) = @_;
    local @CALL = @calls;
    my $res = hit($app, path => '/u', env => $env);
    return split /\n/, join '', @{ $res->[2] };
}

# ---- the shapes -----------------------------------------------------------

{
    my @u = urls(
        [ 'home' ],
        [ 'books' ],
        [ 'book', id => 42 ],
        [ 'tag', id => 7, tag => 'perl' ],
        [ 'file', path => 'a/b/c.txt' ],
        [ 'admin_books' ],
        [ 'book_new' ],
    );
    is $u[0], '/',                'a static route at the root';
    is $u[1], '/books',           'a static route is its declared path';
    is $u[2], '/books/42',        'one capture is filled';
    is $u[3], '/b/7/tags/perl',   'two captures are filled, in order';
    is $u[4], '/files/a/b/c.txt', 'a *splat keeps its slashes';
    is $u[5], '/admin/books',     'a scoped route carries its prefix';
    is $u[6], '/books',
        'a name resolves to its own record, not another method on the path';
}

# ---- the round trip: the builder against the matcher ----------------------

{
    # every kind, with captures chosen to be awkward but legal
    my @cases = (
        [ home        => {} ],
        [ books       => {} ],
        [ book        => { id => 42 } ],
        [ book        => { id => 'a b' } ],
        [ book        => { id => 'x?y#z' } ],
        [ book        => { id => "caf\x{e9}" } ],
        [ book        => { id => '100%' } ],
        [ tag         => { id => 7, tag => 'perl' } ],
        [ file        => { path => 'a/b/c.txt' } ],
        [ file        => { path => 'deep/a b/c?d' } ],
        [ admin_books => {} ],
    );

    my $rt = UF->punk_app->{router};
    for my $case (@cases) {
        my ($name, $caps) = @$case;
        my ($url) = urls([ $name, %$caps ]);
        like $url, qr{^/}, "$name: builds a rooted path" or next;

        # what the server hands the router is the DECODED path, which is the
        # whole reason a '/' in a :param is refused rather than encoded
        my $path = $url;
        $path =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;

        # match returns (idx, \%caps) on a dynamic hit, (undef, \@allow) on a
        # 405 and () on a miss - so a second return value only means captures
        # when the first one is defined
        my ($idx, $got) = $rt->match('GET', $path);
        unless (defined $idx) {
            $got = undef;
            $idx = $rt->match_static('GET', $path);
        }
        ok defined $idx, "$name: the URL it built routes back";

        if (defined $idx && $got) {
            # A capture comes back as the UTF-8 BYTES url_for wrote, whatever
            # internal form it went in as - which is the point of encoding
            # SvPVutf8 rather than the raw PV. upgrade-then-encode names that
            # byte string for a flagged and an unflagged argument alike.
            my %want = map {
                my $v = $caps->{$_};
                utf8::upgrade($v);
                utf8::encode($v);
                ($_ => $v)
            } keys %$caps;
            is_deeply $got, \%want, "$name: with the same captures";
        }
    }
}

# ---- encoding -------------------------------------------------------------

{
    my @u = urls(
        [ 'book', id => 'a b' ],
        [ 'book', id => 'a?b' ],
        [ 'book', id => 'a#b' ],
        [ 'book', id => 'a%b' ],
        [ 'book', id => 'a&b' ],
        [ 'book', id => "caf\x{e9}" ],
        [ 'book', id => 'a-_.~z' ],
        [ 'file', path => 'a/b c' ],
        [ 'books', q => 'a b&c=d' ],
    );
    is $u[0], '/books/a%20b',   'a space is %20, never +';
    is $u[1], '/books/a%3Fb',   'a question mark is encoded in a capture';
    is $u[2], '/books/a%23b',   'and a hash';
    is $u[3], '/books/a%25b',   'and a percent, so the value is not re-read';
    is $u[4], '/books/a%26b',   'and an ampersand';
    is $u[5], "/books/caf%C3%A9",
        'a character string encodes its UTF-8 bytes, not its code points';
    is $u[6], '/books/a-_.~z',  'RFC 3986 unreserved passes through';
    is $u[7], '/files/a/b%20c',
        'a splat keeps slashes and encodes everything else';
    is $u[8], '/books?q=a%20b%26c%3Dd',
        'a query value encodes the separators it would otherwise become';
}

{
    # the bytes-vs-characters seam: the same text, two internal forms, one URL
    my $chars = "caf\x{e9}";
    my $bytes = "caf\x{e9}";
    utf8::upgrade($chars);
    utf8::downgrade($bytes);
    my @u = urls([ 'book', id => $chars ], [ 'book', id => $bytes ]);
    is $u[0], $u[1],
        'an upgraded and a downgraded string build the same URL';
    is $u[0], '/books/caf%C3%A9', 'and it is the UTF-8 one';
}

# ---- the croaks -----------------------------------------------------------

{
    my @u = urls(
        [ 'book' ],
        [ 'book', id => '' ],
        [ 'book', id => undef ],
        [ 'book', id => 'a/b' ],
        [ 'book', id => {} ],
        [ 'nosuch' ],
        [ 'tag', id => 1 ],
    );
    like $u[0], qr/no value for :id/,
        'a missing capture croaks, naming it';
    like $u[1], qr/:id is empty/,
        'an empty capture croaks - the route needs a character there';
    like $u[2], qr/no value for :id/,
        'undef is a missing capture, not an empty one';
    like $u[3], qr{:id contains '/'.*PATH_INFO arrives percent-DECODED}s,
        'a slash in a :param croaks, and says why encoding it would not help';
    like $u[3], qr/\*splat is the segment that takes slashes/,
        'and names the form that does take one';
    like $u[4], qr/:id is a HASH - a capture is one value/,
        'a reference capture croaks';
    like $u[5], qr/no route is named 'nosuch'/,
        'an unknown name croaks, naming it';
    like $u[6], qr/no value for :tag/,
        'the second of two captures is checked too';
}

# ---- the query string -----------------------------------------------------

{
    my @u = urls(
        [ 'books', page => 2 ],
        [ 'books', page => 2, q => 'x' ],
        [ 'books', q => 'x', page => 2 ],
        [ 'book', id => 42, page => 2 ],
        [ 'books', flag => undef ],
        [ 'books', tag => [ 'b', 'a' ] ],
        [ 'book', id => 42, query => { id => 9 } ],
        [ 'books', a => 1, b => 2, c => 3, d => 4 ],
    );
    is $u[0], '/books?page=2',        'a leftover argument is a query pair';
    is $u[1], '/books?page=2&q=x',    'two are sorted';
    is $u[2], $u[1],
        'and the argument order does not change the URL - the point of sorting';
    is $u[3], '/books/42?page=2',
        'captures and query in one call: capture first, then the rest';
    is $u[4], '/books?flag',          'an undef value is the bare key';
    is $u[5], '/books?tag=b&tag=a',
        'an arrayref repeats the key in the array order, not sorted';
    is $u[6], '/books/42?id=9',
        'an explicit query hash can use a name the route captures';
    is $u[7], '/books?a=1&b=2&c=3&d=4', 'keys sort bytewise';
}

{
    my @u = urls([ 'books', page => 2, query => { q => 'x' } ]);
    like $u[0], qr/'page' names no capture, and `query` was given/,
        'a leftover argument beside an explicit query hash is a mistake';
}

{
    # the assertion that matters: the request side reads back what was written
    my ($url) = urls([ 'books', q => 'a b&c=d', 'n' => 2 ]);
    my ($qs) = $url =~ /\?(.*)$/;
    my $res = hit($app, path => '/u', query => $qs);
    is $res->[0], 200, 'the query string it built is one a request accepts';

    # decode it the way Punk::Request does and compare
    my %got;
    for my $pair (split /&/, $qs) {
        my ($k, $v) = split /=/, $pair, 2;
        for ($k, $v) { next unless defined; s/\+/ /g; s/%([0-9A-Fa-f]{2})/chr hex $1/ge }
        $got{$k} = $v;
    }
    is_deeply \%got, { q => 'a b&c=d', n => 2 },
        'and it decodes back to exactly the pairs that went in';
}

# ---- the prefix -----------------------------------------------------------

{
    # SCRIPT_NAME alone: the application is mounted under /app by its server
    my @u = urls_env({ SCRIPT_NAME => '/app' },
        [ 'books' ], [ 'book', id => 42 ], [ 'book', id => 42, absolute => 1 ]);
    is $u[0], '/app/books',    'SCRIPT_NAME is in front of a static route';
    is $u[1], '/app/books/42', 'and of a dynamic one';
    is $u[2], 'https://example.com/app/books/42',
        'an absolute URL carries it too, after the origin';
}

{
    # a path on `host`: a proxy strips /site before Punk sees the request, so
    # SCRIPT_NAME is empty and only configuration knows
    {
        package UFP;
        use Punk;
        host 'https://example.com/site';
        get '/books' => \&main::show, { name => 'books' };
        get '/u' => \&main::build, { name => 'u' };
    }
    my $pa = UFP->to_app;
    local @CALL = ([ 'books' ], [ 'books', absolute => 1 ]);
    my $res = hit($pa, path => '/u');
    my @u = split /\n/, join '', @{ $res->[2] };
    is $u[0], '/site/books',
        'the path on `host` is in front of a relative URL';
    is $u[1], 'https://example.com/site/books',
        'and an absolute one is the bare origin plus it, not the host twice';

    # both layers at once
    local @CALL = ([ 'books' ]);
    my $res2 = hit($pa, path => '/u', env => { SCRIPT_NAME => '/mnt' });
    my ($both) = split /\n/, join '', @{ $res2->[2] };
    is $both, '/site/mnt/books',
        'a proxy prefix and a mount prefix are layers, in that order';
}

# ---- absolute -------------------------------------------------------------

{
    my @u = urls_env({ HTTP_HOST => 'example.com', 'psgi.url_scheme' => 'https' },
        [ 'book', id => 1, absolute => 1 ]);
    is $u[0], 'https://example.com/books/1', 'the canonical host';

    my @t = urls_env({ HTTP_HOST => 'shop.example.com', 'psgi.url_scheme' => 'https' },
        [ 'book', id => 1, absolute => 1 ]);
    is $t[0], 'https://shop.example.com/books/1',
        'an allowlisted host builds on itself - the multi-tenant case';

    my @x = urls_env({ HTTP_HOST => 'evil.test', 'psgi.url_scheme' => 'https' },
        [ 'book', id => 1, absolute => 1 ]);
    is $x[0], 'https://example.com/books/1',
        'an unknown Host gets the canonical origin, never the header';
}

{
    {
        package UFNH;
        use Punk;
        get '/books' => \&main::show, { name => 'books' };
        get '/u' => \&main::build, { name => 'u' };
    }
    my $na = UFNH->to_app;
    local @CALL = ([ 'books', absolute => 1 ], [ 'books' ]);
    my $res = hit($na, path => '/u');
    my @u = split /\n/, join '', @{ $res->[2] };
    like $u[0], qr/declared no `host`/,
        'absolute without a host croaks rather than guessing from the request';
    is $u[1], '/books', 'a relative URL still works without one';
}

# ---- it composes with the rest of the context -----------------------------

{
    my $res = hit($app, path => '/redir');
    is $res->[0], 302, 'redirect to a built URL redirects';
    my %h = @{ $res->[1] };
    is $h{Location}, '/books/7', 'and the Location is what url_for returned';
}

done_testing;
