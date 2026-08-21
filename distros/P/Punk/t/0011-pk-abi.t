#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk ();

# pk_abi.h - Punk's own C ABI. Everything here goes through the TABLE, not the
# static functions behind it: t/lib is not involved, the observers are C
# functions registered through PK_ABI.on_request / on_response, and the values
# they record were read back through PK_ABI's accessors. A mis-ordered
# initialiser or a signature that drifted from the header shows up here as a
# wrong value rather than as nothing at all.

# ---- before anything registers ----------------------------------------------
# Registration is process-global and there is no deregistration, so the
# "nobody is listening" assertions have to come first, in this order.
{
    package QuietApp;
    use Punk;
    get '/q' => sub { $_[0]->text('quiet') };
    package main;
}
{
    my $app = QuietApp->to_app;
    my $r = $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/q' });
    is($r->[0], 200, 'with no observer registered the app answers normally');
    is($r->[2][0], 'quiet', 'and the body is untouched');
    my $ev = Punk::_abi_selftest_events();
    is(scalar @$ev, 0, 'nothing was recorded, because nothing was registered');
}

# ---- the table ---------------------------------------------------------------
{
    ok(Punk::_abi_ptr() > 0, '_abi_ptr hands back a non-zero address');
    is(Punk::_abi_selftest_install(), 1,
        'a C consumer resolves the table, matches PK_ABI_VERSION and registers');
    is(Punk::_abi_selftest_install(), 1, 'registering again is idempotent');
}

# ---- the application ---------------------------------------------------------
sub petstore {
    return {
        openapi => '3.1.0',
        info    => { title => 'Petstore', version => '1' },
        paths   => {
            '/pets' => {
                get => { operationId => 'listPets',
                         responses => { 200 => { description => 'ok' } } },
            },
        },
    };
}

{
    package AbiApp;
    use Punk;

    api main::petstore() => { handlers => {
        listPets => sub { $_[0]->json({ pets => [] }) },
    } };

    mount '/mounted' => sub {
        return [ 201, [ 'Content-Type' => 'text/plain' ], ['from the mount'] ];
    };

    get  '/users/:id' => sub { $_[0]->text('user ' . $_[0]->param('id')) };
    post '/users'     => sub { $_[0]->text('made') };
    get  '/boom'      => sub { die "went wrong\n" };
    get  '/slow'      => sub {
        my ($c) = @_;
        $c->timer(0)->then(sub { $c->text('late') });
    };
    get  '/big' => { cb => sub { $_[0]->text('big') }, max_body => 4 };

    package main;
}

my $app = AbiApp->to_app;

sub hit {
    my ($method, $path, %env) = @_;
    Punk::_abi_selftest_events();            # drain
    my $res = $app->({ REQUEST_METHOD => $method, PATH_INFO => $path, %env });
    return ($res, Punk::_abi_selftest_events());
}

sub only {                                   # the one event of a kind
    my ($ev, $kind) = @_;
    my @m = grep { $_->{kind} eq $kind } @$ev;
    return @m == 1 ? $m[0] : undef;
}

# ---- one event of each kind, on every path ----------------------------------
my @paths = (
    [ 'a matched route',  GET  => '/users/7',    200 ],
    [ 'a 404',            GET  => '/nope',       404 ],
    [ 'a 405',            GET  => '/users',      405 ],
    [ 'a PSGI mount',     GET  => '/mounted/x',  201 ],
    [ 'an API operation', GET  => '/pets',   200 ],
    [ 'a handler that died', GET => '/boom',     500 ],
    [ 'an async handler', GET  => '/slow',       200 ],
);

for my $case (@paths) {
    my ($what, $method, $path, $status) = @$case;
    my ($res, $ev) = hit($method, $path);
    is($res->[0], $status, "$what answers $status");
    is(scalar(grep { $_->{kind} eq 'request' } @$ev), 1,
        "$what fires exactly one request event");
    is(scalar(grep { $_->{kind} eq 'response' } @$ev), 1,
        "$what fires exactly one response event");
    is(only($ev, 'response')->{status}, $status,
        "$what reports the final status through status_of");
}

# ---- ordering and identity ---------------------------------------------------
{
    my ($res, $ev) = hit(GET => '/users/7');
    is($ev->[0]{kind}, 'request',  'the request event comes first');
    is($ev->[1]{kind}, 'response', 'and the response event second');

    ok($ev->[0]{mark} > 0, 'the request observer could write to the stash');
    is($ev->[1]{mark}, $ev->[0]{mark},
        'the response observer reads its own mark back: ONE context per request');

    is($_->{has_env},   1, 'env_of works in the ' . $_->{kind} . ' observer')
        for @$ev;
    is($_->{has_app},   1, 'app_of works in the ' . $_->{kind} . ' observer')
        for @$ev;
    is($_->{has_match}, 1, 'match_of works in the ' . $_->{kind} . ' observer')
        for @$ev;
    is($_->{has_stash}, 1, 'stash_of works in the ' . $_->{kind} . ' observer')
        for @$ev;
}

# ---- route_pattern_of: the pattern, never the path --------------------------
{
    my ($res, $ev) = hit(GET => '/users/7');
    is(only($ev, 'response')->{route}, '/users/:id',
        'route_pattern_of gives the DECLARED path, not /users/7');
    is(only($ev, 'request')->{route}, undef,
        'and undef before routing has happened');
}

{
    my ($res, $ev) = hit(GET => '/nope');
    is(only($ev, 'response')->{route}, undef, '404: no route to name');
}
{
    my ($res, $ev) = hit(GET => '/mounted/x');
    is(only($ev, 'response')->{route}, undef, 'mount: no route to name');
}

# ---- operation_of ------------------------------------------------------------
{
    my ($res, $ev) = hit(GET => '/pets');
    is(only($ev, 'response')->{operation}, 'listPets',
        'operation_of names the API operation');
    is(only($ev, 'response')->{route}, undef,
        'an API operation has no route pattern, it has an operation id');
}

# ---- the paths that never reach punk_deliver --------------------------------
{
    my ($res, $ev) = hit(POST => '/users',
        CONTENT_LENGTH => 99, CONTENT_TYPE => 'text/plain');
    is($res->[0], 200, 'a POST under the ceiling is served');

    ($res, $ev) = hit(GET => '/big',
        CONTENT_LENGTH => 4_000, CONTENT_TYPE => 'text/plain');
    is($res->[0], 413, 'max_body refuses before the hook chain');
    is(scalar(grep { $_->{kind} eq 'response' } @$ev), 1,
        'and the 413 still fires exactly one response event');
    is(only($ev, 'response')->{status}, 413, 'with the right status');
}

# ---- the error path reports what was actually sent --------------------------
{
    my ($res, $ev) = hit(GET => '/boom');
    is(only($ev, 'response')->{status}, 500,
        'a died handler reports the 500 that went out, not the handler');
}

# ---- $c->match->{route}: the POD claim, now true -----------------------------
{
    package MatchApp;
    use Punk;
    our $seen;
    get '/m/:id' => sub {
        my ($c) = @_;
        $seen = $c->match->{route};
        $c->text('ok');
    };
    package main;

    my $m = MatchApp->to_app;
    $m->({ REQUEST_METHOD => 'GET', PATH_INFO => '/m/3' });
    ok(ref $MatchApp::seen eq 'HASH', '$c->match carries the route record');
    is($MatchApp::seen->{path}, '/m/:id', 'whose path is the declared pattern');
    is($MatchApp::seen->{method}, 'GET', 'and which names the method');
}

# ---- v2 on_query: the OTHER database path -----------------------------------
# Punk::Model::DBI is a second, separate backend from DBIx::Loop's, and an
# application using the default `model` generates no DBIx::Loop traffic at
# all. Instrumenting only that one would leave this whole class of application
# silent.
SKIP: {
    eval { require DBI; require DBD::SQLite; 1 }
        or skip 'DBI + DBD::SQLite required', 6;
    require Punk::Model;

    {
        package T::Abi::Book;
        use Punk::Model;
        table 'books';
        field id     => { type => 'integer', primary => 1 };
        field title  => { type => 'string' };
    }

    my $model = T::Abi::Book->_instantiate({ dsn => 'dbi:SQLite:dbname=:memory:' });
    $model->backend->dbh->do(
        'CREATE TABLE books (id INTEGER PRIMARY KEY, title TEXT)');

    my ($s0, $d0, $ok0) = Punk::_abi_selftest_queries();
    $model->create({ title => 'Neuromancer' });
    my ($s1, $d1, $ok1, $nbind, $sql) = Punk::_abi_selftest_queries();

    ok($s1 > $s0, 'a model write is observed through on_query');
    is($d1 - $d0, $s1 - $s0, 'every statement start settled');
    ok($ok1 > $ok0, 'and is reported as having succeeded');

    my ($s2) = Punk::_abi_selftest_queries();
    is($model->get(id => 1)->{title}, 'Neuromancer', 'the row round-tripped');
    my ($s3, $d3, $ok3, $bind3, $sql3) = Punk::_abi_selftest_queries();
    ok($s3 > $s2, 'a model read is observed too');
    like($sql3, qr/SELECT/i, 'the observer is handed the statement text');
    unlike($sql3, qr/Neuromancer/,
        'and never a bind value: the literal data does not reach an observer');
}

done_testing;
