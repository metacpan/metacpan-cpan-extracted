#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Punk::Model;

BEGIN {
    eval { require DBI; require DBD::SQLite; 1 }
        or plan skip_all => 'DBI + DBD::SQLite required for these tests';
}

# Punk::Model::DBI over SQLite: CRUD round-trips, prepared-statement reuse
# through DBI's statement cache, and keyset pagination (opaque next token,
# has_more_data, seek continuation).

{
    package T::Model::Book;
    use Punk::Model;
    table 'books';
    field id      => { type => 'integer', primary => 1 };
    field title   => { type => 'string', required => 1, minLength => 1 };
    field author  => { type => 'string' };
    field created => { type => 'string' };
}

my $model = T::Model::Book->_instantiate({ dsn => 'dbi:SQLite:dbname=:memory:' });
my $dbh   = $model->backend->dbh;
$dbh->do(q{
    CREATE TABLE books (
        id      INTEGER PRIMARY KEY AUTOINCREMENT,
        title   TEXT NOT NULL,
        author  TEXT,
        created TEXT DEFAULT CURRENT_TIMESTAMP
    )
});

isa_ok($model->backend, 'Punk::Model::DBI', 'the default backend');

# ---- create + get -----------------------------------------------------------
my $b = $model->create({ title => 'Neuromancer', author => 'Gibson' });
is($b->{id}, 1, 'create returns the row with its autoincrement key');
is($b->{title}, 'Neuromancer', 'and the inserted data');
ok(defined $b->{created}, 'server default came back on the row');

is($model->get(id => 1)->{author}, 'Gibson', 'get by primary key');
is($model->get(id => 42), undef, 'get miss is undef');

# ---- update -----------------------------------------------------------------
my $u = $model->update({ id => 1, author => 'William Gibson' });
is($u->{author}, 'William Gibson', 'update returns the changed row');
is($model->get(id => 1)->{author}, 'William Gibson', 'change persisted');

# ---- more rows, filter, delete ----------------------------------------------
$model->create({ title => 'Snow Crash',  author => 'Stephenson' });
$model->create({ title => 'Cryptonomicon', author => 'Stephenson' });
$model->create({ title => 'Accelerando', author => 'Stross' });

is(scalar @{ $model->search({ author => 'Stephenson' }, {})->{rows} }, 2,
    'equality filter narrows the set');
is($model->delete(id => 4), 1, 'delete returns the affected count');
is($model->get(id => 4), undef, 'and the row is gone');
is($model->delete(id => 4), 0, 'deleting nothing is a zero count');

# ---- prepared-statement reuse ----------------------------------------------
{
    my $before = scalar keys %{ $dbh->{CachedKids} };
    $model->get(id => $_) for 1 .. 3;        # same SQL each time
    $model->search({ author => 'Stross' }, {}) for 1 .. 3;
    my $after = scalar keys %{ $dbh->{CachedKids} };
    is($after, $before, 'repeated queries reuse cached statements, no growth');
    ok((grep { / FROM / } keys %{ $dbh->{CachedKids} }),
        'statements are held in the DBI cache');
}

# ---- keyset pagination ------------------------------------------------------
{
    # rows now: 1 Neuromancer, 2 Snow Crash, 3 Cryptonomicon (4 was deleted)
    my $p1 = $model->search({}, { limit => 2 });
    is(scalar @{ $p1->{rows} }, 2, 'first page respects the limit');
    is($p1->{rows}[0]{id}, 1, 'ordered by primary key');
    is($p1->{has_more_data}, 1, 'has_more_data flags a further page');
    ok(defined $p1->{next} && length $p1->{next}, 'a next token is offered');
    unlike($p1->{next}, qr/[^A-Za-z0-9_-]/, 'the token is url-safe and opaque');

    my $p2 = $model->search({}, { limit => 2, after => $p1->{next} });
    is($p2->{rows}[0]{id}, 3, 'the second page seeks past the first');
    is($p2->{has_more_data}, 0, 'no more pages after the last');
    is($p2->{next}, undef, 'and no continuation token');

    my @seen = map { $_->{id} } @{ $p1->{rows} }, @{ $p2->{rows} };
    is_deeply(\@seen, [ 1, 2, 3 ], 'the pages cover every row once, in order');

    eval { $model->search({}, { after => 'not a real token' }) };
    like($@, qr/invalid pagination token/, 'a malformed token is rejected');
}

# ---- validation still runs through the DBI backend --------------------------
eval { $model->create({ author => 'anon' }) };
like($@, qr/validation failed/, 'a missing required title croaks before the insert');

# ---- one shared connection per database, not one per model ------------------
{
    package T::Model::Author;
    use Punk::Model;
    table 'authors';
    field id   => { type => 'integer', primary => 1 };
    field name => { type => 'string' };
}
{
    # a second model on the SAME dsn shares the pooled handle
    my $author = T::Model::Author->_instantiate(
        { dsn => 'dbi:SQLite:dbname=:memory:' });
    is($author->backend->dbh, $model->backend->dbh,
        'two models, one dsn -> a single shared connection');
    # and therefore see each other's schema on that one connection
    $author->backend->dbh->do(
        'CREATE TABLE authors (id INTEGER PRIMARY KEY, name TEXT)');
    my $a = $author->create({ name => 'Gibson' });
    is($a->{id}, 1, 'the shared connection serves the second model too');

    # The quoted-identifier and statement caches hang off the shared
    # connection, so two models with the same key column must not read each
    # other's statement - the table is part of the cache key.
    is($author->get(id => 1)->{name}, 'Gibson',
        'a second model on the shared connection gets its own row');
    is($model->get(id => 1)->{title}, 'Neuromancer',
        'and the first model still gets its own, not the second table\'s');
    is($author->get(id => 99), undef, 'a miss is still a miss');
    is($author->delete(id => 99), 0,
        'delete on the shared connection is keyed by table too');
    is($model->get(id => 1)->{title}, 'Neuromancer', 'and did not hit books');

    # a different dsn is a different pooled connection
    my $dir   = File::Temp->newdir;
    my $other = T::Model::Author->_instantiate(
        { dsn => "dbi:SQLite:dbname=$dir/other.db" });
    isnt($other->backend->dbh, $model->backend->dbh,
        'a different dsn -> a separate connection');
}

done_testing();
