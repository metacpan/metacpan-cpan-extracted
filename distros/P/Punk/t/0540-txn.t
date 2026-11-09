#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use File::Temp ();

BEGIN {
    eval { require DBI; require DBD::SQLite; 1 }
        or plan skip_all => 'DBI + DBD::SQLite required for these tests';
}

# $c->txn on both backends: the block's value comes back, a die rolls back
# and rethrows, nested croaks on DBI, a model on another database croaks,
# $tx->model after the block croaks - and the one place the backends
# differ, pinned in both directions: on Punk::Model::DBI a model reached
# through $c->model inside the block is IN the transaction (one connection
# per worker), on Punk::Model::DBIx::Loop it is OUTSIDE (DBIx::Loop pins a
# transaction to one pool slot and plain statements never join).

my $dir = File::Temp->newdir;
my %DSN = map { $_ => "dbi:SQLite:dbname=$dir/$_.db" } qw(dbi loop other);
for my $k (keys %DSN) {
    my $dbh = DBI->connect($DSN{$k}, undef, undef, { RaiseError => 1 });
    $dbh->do('CREATE TABLE orders (id INTEGER PRIMARY KEY AUTOINCREMENT, sku TEXT NOT NULL, qty INTEGER)');
    $dbh->do('CREATE TABLE stock  (id INTEGER PRIMARY KEY AUTOINCREMENT, sku TEXT NOT NULL, held INTEGER NOT NULL DEFAULT 0)');
    $dbh->do("INSERT INTO stock (sku, held) VALUES ('widget', 0)");
    $dbh->disconnect;
}
sub rows { my ($k, $sql) = @_;
    my $dbh = DBI->connect($DSN{$k}, undef, undef, { RaiseError => 1 });
    my $r = $dbh->selectall_arrayref($sql, { Slice => {} }); $dbh->disconnect; $r }
sub body { my ($r) = @_; join '', @{ $r->[2] } }

# the same three models under each application's namespace
for my $app (qw(TxDbi TxLoop)) {
    eval qq{
        package ${app}::Model::Order;  use Punk::Model;
        table 'orders';
        field id => { type => 'integer', primary => 1 };
        field sku => { type => 'string', required => 1 };
        field qty => { type => 'integer' };
        package ${app}::Model::Stock;  use Punk::Model;
        table 'stock';
        field id => { type => 'integer', primary => 1 };
        field sku => { type => 'string' };
        field held => { type => 'integer' };
        package ${app}::Model::Other;  use Punk::Model;
        table 'orders';
        database 'other';
        field id => { type => 'integer', primary => 1 };
        field sku => { type => 'string' };
        1;
    } or die $@;
}

# ============================================================================
# Punk::Model::DBI
# ============================================================================
{
    package TxDbi;
    use Punk;
    database dsn => $DSN{dbi};
    database other => { dsn => $DSN{other} };
    model 'Order';
    model 'Stock';
    model 'Other';

    get '/ok' => sub {
        my ($c) = @_;
        my $v = $c->txn(sub {
            my ($tx) = @_;
            my $o = $tx->model('Order')->create({ sku => 'widget', qty => 2 });
            $tx->model('Stock')->update({ id => 1, held => 2 });
            return { order => $o->{id}, active => $tx->is_active,
                     name => $tx->name, backend => $tx->backend,
                     handle => ref $tx->handle,
                     seen => $tx->model('Order')->count({ sku => 'widget' }) };
        });
        return $c->json($v);
    };
    get '/die' => sub {
        my ($c) = @_;
        $c->txn(sub {
            my ($tx) = @_;
            $tx->model('Order')->create({ sku => 'doomed', qty => 1 });
            $c->model('Order')->create({ sku => 'doomed-via-c', qty => 1 });
            $tx->model('Stock')->update({ id => 1, held => 99 });
            die "boom\n";
        });
        return $c->text('not reached');
    };
    get '/nested' => sub {
        my ($c) = @_;
        $c->txn(sub { $c->txn(sub { 1 }) });
        return $c->text('not reached');
    };
    get '/cross' => sub {
        my ($c) = @_;
        $c->txn(sub { $_[0]->model('Other') });
        return $c->text('not reached');
    };
    get '/after' => sub {
        my ($c) = @_;
        my $kept;
        $c->txn(sub { $kept = $_[0]; 1 });
        my $e = ''; eval { $kept->model('Order') } or $e = $@;
        return $c->text("active=" . $kept->is_active . " err=$e");
    };
    get '/named' => sub {
        my ($c) = @_;
        my $v = $c->txn(other => sub {
            my ($tx) = @_;
            $tx->model('Other')->create({ sku => 'elsewhere' });
            return $tx->name;
        });
        return $c->text($v);
    };
    get '/named-wrong' => sub {
        my ($c) = @_;
        $c->txn(other => sub { $_[0]->model('Order') });
        return $c->text('not reached');
    };
    get '/nodb'   => sub { $_[0]->txn(nope => sub { 1 }) };
    get '/nocode' => sub { $_[0]->txn('not code') };
    get '/handle' => sub {
        my ($c) = @_;
        my $n = $c->txn(sub {
            my ($tx) = @_;
            $tx->handle->do("INSERT INTO orders (sku, qty) VALUES ('raw', 7)");
            return $tx->model('Order')->count({ sku => 'raw' });
        });
        return $c->text("raw=$n");
    };
    package main;
}

my $dbi = TxDbi->to_app;
{
    my $r = hit($dbi, path => '/ok');
    is($r->[0], 200, 'DBI: the block ran');
    my %h = @{ $r->[1] };
    like(body($r), qr/"order":1/, 'DBI: the block\'s value came back');
    like(body($r), qr/"seen":1/, 'DBI: a count inside the block sees the uncommitted row');
    like(body($r), qr/"active":1/, 'DBI: $tx->is_active inside the block');
    like(body($r), qr/"name":"default"/, 'DBI: $tx->name is the database');
    like(body($r), qr/"backend":"Punk::Model::DBI"/, 'DBI: $tx->backend names the class');
    like(body($r), qr/"handle":"DBI::db"/, 'DBI: $tx->handle is the DBI handle');
    is_deeply(rows(dbi => 'SELECT sku, qty FROM orders'), [ { sku => 'widget', qty => 2 } ],
        'DBI: the order committed');
    is(rows(dbi => 'SELECT held FROM stock')->[0]{held}, 2, 'DBI: and the stock update with it');
}
{
    my $r = hit($dbi, path => '/die');
    is($r->[0], 500, 'DBI: a die inside the block is an error');
    like(body($r), qr/boom/, 'DBI: carrying the block\'s own message');
    is(scalar @{ rows(dbi => "SELECT * FROM orders WHERE sku LIKE 'doomed%'") }, 0,
        'DBI: both writes rolled back - the one through $tx->model AND the one through $c->model');
    is(rows(dbi => 'SELECT held FROM stock')->[0]{held}, 2, 'DBI: the stock update rolled back too');
    is(scalar @{ rows(dbi => 'SELECT * FROM orders') }, 1, 'DBI: the earlier commit is untouched');
}
{
    my $r = hit($dbi, path => '/ok');
    is($r->[0], 200, 'DBI: the connection is usable again after a rollback');
    is(scalar @{ rows(dbi => 'SELECT * FROM orders') }, 2, 'DBI: and commits again');
}
{
    my $r = hit($dbi, path => '/nested');
    is($r->[0], 500, 'DBI: a transaction inside a transaction is an error');
    like(body($r), qr/already open on this connection - nested transactions are not supported/,
        'DBI: saying why');
    is(hit($dbi, path => '/ok')->[0], 200, 'DBI: and the outer one was rolled back, not left open');
}
{
    my $r = hit($dbi, path => '/cross');
    is($r->[0], 500, 'DBI: a model on another database croaks');
    like(body($r), qr/model 'Other' lives on database 'other', and this transaction is on 'default'/,
        'DBI: naming both');
}
{
    my $r = hit($dbi, path => '/after');
    like(body($r), qr/active=0 err=.*the transaction is over/,
        'DBI: $tx->model after the block croaks, and is_active is false');
}
is(body(hit($dbi, path => '/named')), 'other', 'DBI: a named database');
is_deeply(rows(other => 'SELECT sku FROM orders'), [ { sku => 'elsewhere' } ],
    'DBI: and its write landed on that database');
like(body(hit($dbi, path => '/named-wrong')), qr/lives on database 'default', and this transaction is on 'other'/,
    'DBI: the default-database model croaks inside a named transaction');
like(body(hit($dbi, path => '/nodb')), qr/no database 'nope' configured/, 'DBI: an unknown name croaks');
like(body(hit($dbi, path => '/nocode')), qr/txn takes a coderef/, 'DBI: a non-coderef croaks');
is(body(hit($dbi, path => '/handle')), 'raw=1',
    'DBI: a raw statement on $tx->handle is in the transaction with the models');

# ============================================================================
# Punk::Model::DBIx::Loop
# ============================================================================
SKIP: {
    skip 'DBIx::Loop required for the async half', 1
        unless eval { require DBIx::Loop; 1 };
    # the pool is shared per dsn, so the probe's is the one the app uses
    if (my $err = loop_pool_error(TxLoop::Model::Order->_instantiate({
            dsn => $DSN{loop}, backend => 'Punk::Model::DBIx::Loop',
            workers => 2, attr => { PrintError => 0 } }))) {
        skip "the async backend's pool could not fork here: $err", 1;
    }

    {
        package TxLoop;
        use Punk;
        database dsn => $DSN{loop}, backend => 'Punk::Model::DBIx::Loop',
                 workers => 2, attr => { PrintError => 0 };
        model 'Order';
        model 'Stock';

        get '/ok' => sub {
            my ($c) = @_;
            return $c->txn(sub {
                my ($tx) = @_;
                return $tx->model('Order')->create({ sku => 'widget', qty => 2 })
                  ->then(sub {
                        my ($o) = @_;
                        $tx->model('Stock')->update({ id => 1, held => 2 })
                          ->then(sub { $tx->model('Order')->count({ sku => 'widget' }) })
                          ->then(sub { { order => $o->{id}, seen => $_[0],
                                         active => $tx->is_active,
                                         handle => ref $tx->handle,
                                         backend => $tx->backend } });
                  });
            })->then(sub { $c->json($_[0]) });
        };
        get '/die' => sub {
            my ($c) = @_;
            return $c->txn(sub {
                my ($tx) = @_;
                # through $c->model: OUTSIDE the transaction on this backend,
                # so it commits on its own slot - and it goes first, before
                # the transaction's own write takes the database lock
                return $c->model('Order')->create({ sku => 'outside', qty => 1 })
                  ->then(sub { $tx->model('Order')->create({ sku => 'doomed', qty => 1 }) })
                  ->then(sub { die "boom\n" });
            })->then(sub { $c->text('not reached') });
        };
        get '/fail' => sub {
            my ($c) = @_;
            return $c->txn(sub {
                my ($tx) = @_;
                return $tx->model('Order')->create({ sku => 'doomed2', qty => 1 })
                  # a raw statement on the pinned handle that fails
                  ->then(sub { $tx->handle->query('SELECT * FROM no_such_table') });
            })->then(sub { $c->text('not reached') });
        };
        get '/fail-do' => sub {
            my ($c) = @_;
            return $c->txn(sub {
                my ($tx) = @_;
                return $tx->model('Order')->create({ sku => 'doomed3', qty => 1 })
                  ->then(sub { $tx->handle->do('INSERT INTO orders (sku) VALUES (NULL)') });
            })->then(sub { $c->text('not reached') });
        };
        get '/plain' => sub {
            my ($c) = @_;
            # a block returning a plain value commits at once
            return $c->txn(sub { 'plain' })->then(sub { $c->text($_[0]) });
        };
        get '/after' => sub {
            my ($c) = @_;
            my $kept;
            # a block returning a FUTURE: active until it settles, not until
            # the block returns
            return $c->txn(sub { $kept = $_[0]; $kept->model('Order')->count({}) })->then(sub {
                my $e = ''; eval { $kept->model('Order') } or $e = $@;
                $c->text("active=" . $kept->is_active . " err=$e");
            });
        };
        package main;
    }

    my $loop = TxLoop->to_app;
    {
        my $r = hit($loop, path => '/ok');
        is($r->[0], 200, 'Loop: the block ran and the future resolved');
        like(body($r), qr/"order":1/, 'Loop: the block\'s value came back after commit');
        like(body($r), qr/"seen":1/, 'Loop: a count through $tx->model sees the uncommitted row');
        like(body($r), qr/"active":1/, 'Loop: is_active inside the block');
        like(body($r), qr/"handle":"DBIx::Loop::Txn"/, 'Loop: $tx->handle is the pinned handle');
        like(body($r), qr/"backend":"Punk::Model::DBIx::Loop"/, 'Loop: $tx->backend');
        is_deeply(rows(loop => 'SELECT sku, qty FROM orders'), [ { sku => 'widget', qty => 2 } ],
            'Loop: the order committed');
        is(rows(loop => 'SELECT held FROM stock')->[0]{held}, 2, 'Loop: with the stock update');
    }
    {
        my $r = hit($loop, path => '/die');
        is($r->[0], 500, 'Loop: a die inside the block fails the future');
        like(body($r), qr/boom/, 'Loop: with the block\'s message');
        is(scalar @{ rows(loop => "SELECT * FROM orders WHERE sku = 'doomed'") }, 0,
            'Loop: the write through $tx->model rolled back');
        is(scalar @{ rows(loop => "SELECT * FROM orders WHERE sku = 'outside'") }, 1,
            'Loop: the write through $c->model did NOT - it was never in the transaction');
    }
    {
        my $r = hit($loop, path => '/fail');
        is($r->[0], 500, 'Loop: a failed statement on the handle fails the transaction');
        is(scalar @{ rows(loop => "SELECT * FROM orders WHERE sku = 'doomed2'") }, 0,
            'Loop: and the earlier write in the block rolled back with it');
    }
    SKIP: {
        skip 'a do() that fails in the database fails its future from DBIx::Loop 0.07', 3
            unless eval { DBIx::Loop->VERSION(0.07); 1 };
        my $r = hit($loop, path => '/fail-do');
        is($r->[0], 500, 'Loop: a failing do() on the handle fails the transaction');
        like(body($r), qr/NOT NULL constraint/, 'Loop: with the driver\'s message');
        is(scalar @{ rows(loop => "SELECT * FROM orders WHERE sku = 'doomed3'") }, 0,
            'Loop: and the model write before it rolled back');
    }
    is(body(hit($loop, path => '/plain')), 'plain', 'Loop: a plain block value resolves the future');
    like(body(hit($loop, path => '/after')), qr/active=0 err=.*the transaction is over/,
        'Loop: $tx->model after the block croaks');
    is(hit($loop, path => '/ok')->[0], 200, 'Loop: the pool is healthy after the rollbacks');
}

done_testing();
