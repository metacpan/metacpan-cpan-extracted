#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use Punk ();

# url_for over an OpenAPI mount.
#
# An operation has an operationId and a path template with {holes}: a named
# route by another spelling, and an application with an `api` keyword would
# be half-named without this. The ids go into the SAME names table as the
# route names - one namespace - and the entry's SHAPE says which kind it is.
#
# The template is parsed separately from the router's segments, because
# `/files/{name}.json` is legal OpenAPI and the router has no mid-segment
# holes.

my $SPEC = "$FindBin::Bin/test/MyApp/openapi.json";
plan skip_all => 'the fixture spec is missing' unless -f $SPEC;

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

{
    package UA;
    use Punk;
    host 'https://example.com';
    under('/api')->api($SPEC => { stub => 1 });
    get '/u' => \&main::build, { name => 'u' };
}
my $app = UA->to_app;

sub urls {
    local @CALL = @_;
    return split /\n/, join '', @{ hit($app, path => '/u')->[2] };
}

# ---- an operationId is a name ---------------------------------------------

{
    my @u = urls(
        [ 'allBooks' ],
        [ 'getBook', id => 42 ],
        [ 'getBook', id => 42, absolute => 1 ],
        [ 'getBook', id => 42, fields => 'title' ],
        [ 'addBook' ],
    );
    is $u[0], '/api/books',    'an operation with no holes is its path';
    is $u[1], '/api/books/42', 'a hole is filled from the arguments';
    is $u[2], 'https://example.com/api/books/42',
        'absolute joins the origin, then the mount prefix';
    is $u[3], '/api/books/42?fields=title',
        'a leftover argument is a query pair, as on a route';
    is $u[4], '/api/books',
        'two operations on one path each answer to their own id';
}

# ---- the URL it builds reaches the operation ------------------------------

{
    # the round trip, through the mount rather than the router: what url_for
    # writes is what the dispatcher resolves to that operationId
    my ($url) = urls([ 'getBook', id => 42 ]);
    my $res = hit($app, path => $url);
    # 501 is what `stub => 1` answers for an operation with no handler - so
    # it is proof the URL resolved to the operation, where a 404 would mean
    # the builder and the mount's router disagree about the path
    is $res->[0], 501,
        'the built URL resolves to the operation (the stub answers it)';
    isnt $res->[0], 404, 'and is not a path the mount fails to recognise';

    {
        package UAM;
        use Punk;
        under('/api')->api($SPEC => {
            handlers => {
                getBook => sub {
                    my ($c) = @_;
                    $c->json({ op => $c->match->{operation},
                               id => $c->param('id') });
                },
            },
            stub => 1,
        });
        get '/u' => \&main::build, { name => 'u' };
    }
    my $ma = UAM->to_app;
    local @CALL = ([ 'getBook', id => 42 ]);
    my ($u2) = split /\n/, join '', @{ hit($ma, path => '/u')->[2] };
    my $r2 = hit($ma, path => $u2);
    is $r2->[0], 200, 'and with a handler it answers';
    like join('', @{ $r2->[2] }), qr/"op"\s*:\s*"getBook"/,
        'at the operation the name promised';
    like join('', @{ $r2->[2] }), qr/"id"\s*:\s*"?42"?/,
        'with the capture the URL carried';
}

# ---- the template form, which is not the router's ------------------------

{
    # a hole inside a segment, and two holes in one path - neither of which
    # the router's :param segments can express
    my $spec = {
        openapi => '3.1.0',
        info    => { title => 't', version => '1' },
        paths   => {
            '/files/{name}.json'   => { get => { operationId => 'getFile',
                responses => { '200' => { description => 'ok' } } } },
            '/a/{x}/b/{y}'         => { get => { operationId => 'twoHoles',
                responses => { '200' => { description => 'ok' } } } },
            '/plain'               => { get => { operationId => 'plain',
                responses => { '200' => { description => 'ok' } } } },
        },
    };
    {
        package UAT;
        use Punk;
        under('/v1')->api($spec => { stub => 1 });
        get '/u' => \&main::build, { name => 'u' };
    }
    my $ta = UAT->to_app;
    local @CALL = (
        [ 'getFile', name => 'notes' ],
        [ 'twoHoles', x => 1, y => 2 ],
        [ 'plain' ],
        [ 'getFile', name => 'a b' ],
        [ 'getFile' ],
        [ 'getFile', name => 'a/b' ],
    );
    my @u = split /\n/, join '', @{ hit($ta, path => '/u')->[2] };
    is $u[0], '/v1/files/notes.json',
        'a hole inside a segment keeps the text on both sides of it';
    is $u[1], '/v1/a/1/b/2', 'two holes in one path';
    is $u[2], '/v1/plain',   'and a template with none';
    is $u[3], '/v1/files/a%20b.json', 'a hole percent-encodes its value';
    like $u[4], qr/no value for :name/, 'a missing hole croaks, naming it';
    like $u[5], qr{contains '/'.*OpenAPI path template has no segment}s,
        'a slash croaks, and the hint fits OpenAPI rather than naming a splat';
}

# ---- one namespace --------------------------------------------------------

{
    my $err = '';
    eval {
        package UAD;
        use Punk;
        get '/books' => sub {}, { name => 'getBook' };
        under('/api')->api($SPEC => { stub => 1 });
        package main;
        UAD->to_app;
    } or $err = $@;
    like $err, qr/route name 'getBook' is declared twice/,
        'a route named like an operation croaks';
    like $err, qr{GET /books and the operation of that name in the /api mount},
        'and the message names both, saying which is which';
}

{
    # the template hash holds static ROUTES; an operationId is reachable from
    # url_for whatever it is spelled, because it is the spec's name not ours
    my @u = urls([ 'nosuchOp' ]);
    like $u[0], qr/no route is named 'nosuchOp'/,
        'an unknown operationId is an unknown name like any other';
}

done_testing;
