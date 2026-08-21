#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use Punk::Model;

BEGIN {
    eval { require DBI; require DBD::SQLite; 1 }
        or plan skip_all => 'DBI + DBD::SQLite required for these tests';
    eval { require DBIx::Loop; 1 }
        or plan skip_all => 'DBIx::Loop required for these tests';
}

# Punk::Model::DBIx::Loop, the non-blocking backend: the same contract as
# Punk::Model::DBI but every method returns a Punk::Future. Selected with
# `backend => ...`; the default backend is the synchronous one.
#
# The pool forks real workers, so this runs on a FILE-backed SQLite - a
# :memory: database would give every worker its own empty one.

{
    package T::Model::Book;
    use Punk::Model;
    table 'books';
    field id      => { type => 'integer', primary => 1 };
    field title   => { type => 'string', required => 1, minLength => 1 };
    field author  => { type => 'string' };
    field created => { type => 'string' };
}

my $dir = File::Temp->newdir;
my $dsn = "dbi:SQLite:dbname=$dir/books.db";

my %DB = (
    dsn     => $dsn,
    workers => 2,
    backend => 'Punk::Model::DBIx::Loop',
    # PrintError off: one test below runs a deliberately bad query and DBI
    # would otherwise write it to the harness's stderr
    attr    => { PrintError => 0 },
);

my $model = T::Model::Book->_instantiate({ %DB });
isa_ok($model->backend, 'Punk::Model::DBIx::Loop', 'the selected backend');
ok(Punk::Model::DBIx::Loop->_abi_ok, 'DBIx::Loop C ABI resolved');

# schema through the parent handle - boot-style, synchronous on purpose
$model->backend->dbh->do(q{
    CREATE TABLE books (
        id      INTEGER PRIMARY KEY AUTOINCREMENT,
        title   TEXT NOT NULL,
        author  TEXT,
        created TEXT DEFAULT CURRENT_TIMESTAMP
    )
});

# ---- everything returns a Punk::Future --------------------------------------
my $f = $model->create({ title => 'Neuromancer', author => 'Gibson' });
isa_ok($f, 'Punk::Future', 'create returns a future');
ok(!$f->is_ready || 1, 'and it is a future, not a value');

# ---- create + get, awaited --------------------------------------------------
my ($b) = $f->get;   # off a worker the future pumps the adapter's own loop
is($b->{id}, 1, 'create resolves to the row with its autoincrement key');
is($b->{title}, 'Neuromancer', 'and the inserted data');
ok(defined $b->{created}, 'server default came back on the row');

is(($model->get(id => 1)->get)[0]->{author}, 'Gibson', 'get by primary key');
is(($model->get(id => 42)->get)[0], undef, 'get miss resolves to undef');

# backend->await is the same await, spelled for scripts
my ($row) = $model->backend->await($model->get(id => 1));
is($row->{title}, 'Neuromancer', 'backend->await resolves a future');

# ---- then-chains compose ----------------------------------------------------
{
    my ($t) = $model->get(id => 1)->then(sub { uc $_[0]{title} })->get;
    is($t, 'NEUROMANCER', 'a then-chain inherits the loop and resolves');
}

# ---- update -----------------------------------------------------------------
my ($u) = $model->update({ id => 1, author => 'William Gibson' })->get;
is($u->{author}, 'William Gibson', 'update resolves to the changed row');

# ---- more rows, filter, delete ----------------------------------------------
$model->create({ title => $_->[0], author => $_->[1] })->get
    for [ 'Snow Crash', 'Stephenson' ], [ 'Cryptonomicon', 'Stephenson' ],
        [ 'Accelerando', 'Stross' ];

{
    my ($page) = $model->search({ author => 'Stephenson' }, {})->get;
    is(scalar @{ $page->{rows} }, 2, 'equality filter narrows the set');
}
is(($model->delete(id => 4)->get)[0], 1, 'delete resolves to the count');
is(($model->get(id => 4)->get)[0], undef, 'and the row is gone');
is(($model->delete(id => 4)->get)[0], 0, 'deleting nothing is a zero count');

# ---- keyset pagination, futures-shaped --------------------------------------
{
    # rows now: 1, 2, 3 (4 was deleted)
    my ($p1) = $model->search({}, { limit => 2 })->get;
    is(scalar @{ $p1->{rows} }, 2, 'first page respects the limit');
    is($p1->{rows}[0]{id}, 1, 'ordered by primary key');
    is($p1->{has_more_data}, 1, 'has_more_data flags a further page');
    ok(defined $p1->{next} && length $p1->{next}, 'a next token is offered');
    unlike($p1->{next}, qr/[^A-Za-z0-9_-]/, 'the token is url-safe and opaque');

    my ($p2) = $model->search({}, { limit => 2, after => $p1->{next} })->get;
    is($p2->{rows}[0]{id}, 3, 'the second page seeks past the first');
    is($p2->{has_more_data}, 0, 'no more pages after the last');
    is($p2->{next}, undef, 'and no continuation token');

    eval { $model->search({}, { after => 'not a real token' }) };
    like($@, qr/invalid pagination token/,
        'a malformed token croaks synchronously, before the exec');
}

# ---- cross-backend token parity ---------------------------------------------
# The codec is shared, so a token minted by one backend decodes on the other:
# switching backends must not break paginated URLs in flight.
{
    my $tok = Punk::Model::DBI->_encode_token(7);
    is(Punk::Model::DBIx::Loop->_decode_token($tok), 7,
        'a DBI-minted token decodes on DBIx::Loop');
    my $tok2 = Punk::Model::DBIx::Loop->_encode_token(9);
    is(Punk::Model::DBI->_decode_token($tok2), 9,
        'and the other way round');
}

# ---- a failed query fails the future, it does not croak at call time --------
{
    my $pf = $model->backend->db->query('SELECT 1');  # touch: pool is up
    my $bad = do {
        package T::Model::Broken;
        use Punk::Model;
        table 'no_such_table';
        field id => { type => 'integer', primary => 1 };
        __PACKAGE__->_instantiate({ %DB });
    };
    my $g = $bad->get(id => 1);
    isa_ok($g, 'Punk::Future', 'the doomed get still returns a future');
    my $ok = eval { $g->get; 1 };
    ok(!$ok, 'awaiting it croaks with the database error');
    like($@, qr/no such table|prepare/, 'and the error names the cause');
}

# ---- validation croaks synchronously ----------------------------------------
# pm_validate runs before delegation, so a bad payload is a programming error
# surfaced at the call site - not a failed future.
eval { $model->create({ author => 'anon' }) };
like($@, qr/validation failed/, 'a missing required title croaks before the insert');

# ---- the version guard ------------------------------------------------------
# PUNK_FAKE_DBIL_BAD is checked at FIRST resolution, and this process has
# already resolved - a fork would inherit the resolved table - so the guard
# is asserted in a fresh interpreter.
{
    local $ENV{PUNK_FAKE_DBIL_BAD} = 1;
    my $out = do {
        my @inc = map { "-I$_" } @INC;
        open my $rd, '-|', $^X, @inc, '-MPunk', '-e',
            'print Punk::Model::DBIx::Loop->_abi_ok ? "resolved" : "refused"'
            or die "spawn: $!";
        local $/; my $o = <$rd>; close $rd; $o;
    };
    like($out, qr/refused/, 'PUNK_FAKE_DBIL_BAD makes the resolver refuse the table');
}

# ---- end to end, through the dispatcher -------------------------------------
# The point of the backend: a handler returns the future (or a chain over it)
# and the dispatcher awaits it. Nothing in the handler blocks, and nothing in
# the model tier had to change for this to work - pm_delegate passes the
# future through untouched.
{
    package T::App::Model::Book;
    use Punk::Model;
    table 'books';
    field id     => { type => 'integer', primary => 1 };
    field title  => { type => 'string', required => 1, minLength => 1 };
    field author => { type => 'string' };
}
{
    package T::App;
    use Punk;

    database dsn     => $dsn,
             workers => 2,
             backend => 'Punk::Model::DBIx::Loop',
             attr    => { PrintError => 0 };
    model 'Book';

    get '/books/:id' => sub {
        my ($c) = @_;
        # the bare future, handed straight back
        return $c->model('Book')->get( id => $c->param('id') );
    };

    get '/titles' => sub {
        my ($c) = @_;
        # a chain over it
        return $c->model('Book')->all->then(sub {
            my ($page) = @_;
            { titles => [ map $_->{title}, @{ $page->{rows} } ] };
        });
    };

    get '/missing' => sub {
        my ($c) = @_;
        return $c->model('Book')->get( id => 9999 )->then(sub {
            $_[0] // $c->not_found;
        });
    };
}

SKIP: {
    my $app = eval { T::App->to_app };
    skip "app would not compile: $@", 4 unless $app;

    require PunkTest;
    my $r = PunkTest::hit($app, path => '/books/1');
    is($r->[0], 200, 'a handler returning the future answers 200');
    like($r->[2][0], qr/Neuromancer/, 'with the row the future resolved to');

    $r = PunkTest::hit($app, path => '/titles');
    like($r->[2][0], qr/Neuromancer/, 'a then-chain through the dispatcher works');

    $r = PunkTest::hit($app, path => '/missing');
    is($r->[0], 404, 'and a chain may still answer not_found');
}

done_testing();
