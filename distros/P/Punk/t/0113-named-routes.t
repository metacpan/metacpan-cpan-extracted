#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk ();

# `name` as a route option, and the one table it resolves into.
#
#     get '/books/:id' => 'Web::Book#view', { name => 'book' };
#
# Nothing here builds a URL - that is $c->url_for, in t/0114. What is proved
# here is the table it will read: the
# name reaches the compiled record, every name in the application resolves
# to exactly one record index, and a name that could not work fails at the
# line that wrote it rather than at a render.
#
# The reason a name is an identifier and not a string is the template seam:
# Template::Stencil resolves {% url.queue.jobs %} as url->{queue}{jobs}, so a
# dotted name is one a handler can build and a template cannot reach. That is
# a boot croak here, with the underscore convention in the message.

# ---- the option is accepted, everywhere a route is declared ---------------

{
    my $app = eval {
        package NR::Accept;
        use Punk;
        get  '/books'      => sub { $_[0]->text('list') }, { name => 'books' };
        get  '/books/:id'  => sub { $_[0]->text('one')  }, { name => 'book'  };
        post '/books'      => sub { $_[0]->text('new')  }, { name => 'book_create' };
        any  '/ping'       => sub { $_[0]->text('pong') }, { name => 'ping' };
        get  '/spec'       => { cb => sub { $_[0]->text('spec') },
                                name => 'spec' };
        my $admin = under '/admin';
        $admin->get('/books' => sub { $_[0]->text('admin') },
                    { name => 'admin_books' });
        __PACKAGE__->to_app;
    };
    ok $app, 'an application naming its routes compiles' or diag $@;

    my $recs = NR::Accept->punk_app->{router}->records;
    my %name_of = map { ($_->{method} . ' ' . $_->{path}) => $_->{name} }
                  grep { defined $_->{name} } @$recs;

    is $name_of{'GET /books'},        'books',       'a static route is named';
    is $name_of{'GET /books/:id'},    'book',        'a dynamic route is named';
    is $name_of{'POST /books'},       'book_create',
        'two methods on one path are two records and two names';
    is $name_of{'ANY /ping'},         'ping',
        'an ANY route is one record and one name, whatever the method';
    is $name_of{'GET /spec'},         'spec',
        'the one-hashref route form carries the name too';
    is $name_of{'GET /admin/books'},  'admin_books',
        'a scoped verb names the route at its prefixed path';

    # the option is consumed, not passed through as a route option to
    # anything downstream that would not know it
    my ($books) = grep { ($_->{path} // '') eq '/books'
                         && $_->{method} eq 'GET' } @$recs;
    ok !exists $books->{ws} && !exists $books->{sse},
        'naming a route does not mark it as anything else';
}

# ---- the table: name -> record index --------------------------------------

{
    my $names = NR::Accept->punk_app->{names_c};
    is ref $names, 'HASH', 'to_app leaves one names table on the application';

    my $recs = NR::Accept->punk_app->{router}->records;
    is scalar(keys %$names), 6, 'every named route is in it, and nothing else';

    for my $n (qw(books book book_create ping spec admin_books)) {
        my $idx = $names->{$n};
        ok defined $idx, "'$n' resolves to a record index";
        is $recs->[$idx]{name}, $n,
            "'$n' resolves to the record that carries it";
    }

    # the index is the one the dispatcher speaks, so it addresses the record
    # holding the code - which is what url_for walks to build the URL
    is $recs->[ $names->{book} ]{path}, '/books/:id',
        'the index addresses the declared path, captures and all';
    is ref $recs->[ $names->{book} ]{code}, 'CODE',
        'and the same record holds the handler';
}

# ---- the reverse map the build will cross ---------------------------------

# A name resolves to a RECORD index, and building a URL from a dynamic route
# means reaching that record's parsed segments - which live in `recs`,
# indexed by dynamic position, not by record index. dyn_of is the crossing,
# filled in the one loop that fills recs. Nothing uses it until url_for, so
# the invariant is asserted here rather than discovered wrong there.
{
    my $rt    = NR::Accept->punk_app->{router};
    my $recs  = $rt->records;
    my $dyn   = $rt->_dyn_of;

    is scalar @$dyn, scalar @$recs,
        'the map has one entry per compiled record';

    my $dynamic = 0;
    for my $i (0 .. $#$recs) {
        my $path    = $recs->[$i]{path} // '';
        my $is_dyn  = $path =~ m{[:*]} ? 1 : 0;
        $dynamic++ if $is_dyn;
        if ($is_dyn) {
            cmp_ok $dyn->[$i], '>=', 0,
                "a dynamic route ($path) maps to a dynamic position";
        }
        else {
            is $dyn->[$i], -1,
                "a static route ($path) maps to -1, having no segments";
        }
    }
    ok $dynamic, 'the fixture has at least one dynamic route to cross for';

    # the positions are distinct and dense: two records must never share one
    my @pos = sort { $a <=> $b } grep { $_ >= 0 } @$dyn;
    is_deeply \@pos, [ 0 .. $#pos ],
        'dynamic positions are 0..n-1, each used once';
}

# ---- an application that names nothing ------------------------------------

{
    my $app = eval {
        package NR::Unnamed;
        use Punk;
        get '/' => sub { $_[0]->text('hi') };
        __PACKAGE__->to_app;
    };
    ok $app, 'an application naming nothing still compiles' or diag $@;
    my $names = NR::Unnamed->punk_app->{names_c};
    is ref $names, 'HASH', 'and still gets a table';
    is scalar(keys %$names), 0, 'an empty one';
    my $recs = NR::Unnamed->punk_app->{router}->records;
    ok !defined $recs->[0]{name}, 'an unnamed record carries no name key';
}

# ---- what a name may be: the croaks at the keyword ------------------------

sub boot_fails {
    my ($body, $like, $what) = @_;
    my $pkg = 'NRX' . int(rand 1e9);
    eval "package $pkg; use Punk; $body; ${pkg}->to_app; 1";
    like $@ || '', $like, $what;
}

boot_fails q{get '/x' => sub {}, { name => '' }},
    qr/name on GET \/x is empty/,
    'an empty name croaks, naming the route it was on';

boot_fails q{get '/x' => sub {}, { name => undef }},
    qr/name on GET \/x is empty/,
    'name => undef is the same mistake and gets the same message';

boot_fails q{get '/x' => sub {}, { name => 'queue.jobs' }},
    qr/may not contain '\.'.*url\.queue\.jobs.*queue_jobs/s,
    'a dotted name croaks, and the message says why and what to write';

boot_fails q{get '/x' => sub {}, { name => 'my route' }},
    qr/name 'my route' is not an identifier/,
    'a space croaks';

boot_fails q{get '/x' => sub {}, { name => 'book-list' }},
    qr/name 'book-list' is not an identifier/,
    'a hyphen croaks - it is not an identifier in a template either';

boot_fails q{get '/x' => sub {}, { name => 'absolute' }},
    qr/'absolute' is reserved/,
    'absolute is a url_for option, so it cannot be a name';

boot_fails q{get '/x' => sub {}, { name => 'query' }},
    qr/'query' is reserved/,
    'and so is query';

boot_fails q{get '/x' => sub {}, { name => ['a','b'] }},
    qr/name must be a string, not a ARRAY/,
    'a reference croaks - a route has one name, and aliases are not a thing';

boot_fails q{get '/x' => sub {}, { nmae => 'x' }},
    qr/unknown route option 'nmae'/,
    'a typo in the option key still croaks, as every other option does';

# a name that IS an identifier is not refused by any of the above
{
    my $ok = eval q{
        package NR::Fine; use Punk;
        get '/a' => sub {}, { name => 'a' };
        get '/b' => sub {}, { name => 'B9_x' };
        get '/c' => sub {}, { name => '_private' };
        NR::Fine->to_app; 1;
    };
    ok $ok, 'letters, digits, underscores and a leading underscore are fine'
        or diag $@;
}

# ---- one namespace: the duplicate croak ----------------------------------

{
    my $err = '';
    eval {
        package NR::Dup;
        use Punk;
        get  '/books'     => sub {}, { name => 'book' };
        get  '/books/:id' => sub {}, { name => 'book' };
        package main;
        NR::Dup->to_app;
    } or $err = $@;
    like $err, qr/route name 'book' is declared twice/,
        'two routes with one name croak at to_app';
    like $err, qr{GET /books\b.*GET /books/:id},
        'and the message names BOTH routes, so it says which to rename';
}

{
    # the same name on two methods of one path is still two records, and
    # url_for would have had to choose between them
    my $err = '';
    eval {
        package NR::DupMethod;
        use Punk;
        get  '/x' => sub {}, { name => 'x' };
        post '/x' => sub {}, { name => 'x' };
        package main;
        NR::DupMethod->to_app;
    } or $err = $@;
    like $err, qr/route name 'x' is declared twice: GET \/x and POST \/x/,
        'one name over two methods of one path croaks, naming both verbs';
}

{
    # ... and `any` is the way to say "one name, every method"
    my $app = eval {
        package NR::AnyOne;
        use Punk;
        any '/x' => sub { $_[0]->text('x') }, { name => 'x' };
        __PACKAGE__->to_app;
    };
    ok $app, 'an ANY route is the spelling that gives one name every method'
        or diag $@;
    is scalar(keys %{ NR::AnyOne->punk_app->{names_c} }), 1,
        'and it is one entry in the table';
}

# ---- the name does not disturb the route it is on -------------------------

{
    my $app = eval {
        package NR::Serves;
        use Punk;
        get '/books/:id' => sub { $_[0]->text('book ' . $_[0]->param('id')) },
            { name => 'book' };
        __PACKAGE__->to_app;
    };
    ok $app, 'a named route compiles' or diag $@;
    open my $in, '<', \'';
    my $res = $app->({
        REQUEST_METHOD => 'GET', PATH_INFO => '/books/42',
        QUERY_STRING   => '', SERVER_NAME => 'localhost', SERVER_PORT => 80,
        HTTP_HOST      => 'localhost', 'psgi.url_scheme' => 'http',
        'psgi.input'   => $in,
    });
    is $res->[0], 200, 'a named route still routes';
    is join('', @{ $res->[2] }), 'book 42',
        'and still captures - naming is a boot-time fact, not a request one';
}

done_testing;
