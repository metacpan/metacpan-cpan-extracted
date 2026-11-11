#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use File::Temp ();
use Punk::Model;

# The async backend's edges: a configuration with no dsn, a create with no
# known column, an update with no key and one with nothing to change, the
# future() bridge for a raw DBIx::Loop future and its refusal of anything
# else, and await() pumping the adapter's own loop for a future that nothing
# else would settle.

BEGIN {
    eval { require DBI; require DBD::SQLite; 1 }
        or plan skip_all => 'DBI + DBD::SQLite required for these tests';
    eval { require DBIx::Loop; 1 }
        or plan skip_all => 'DBIx::Loop required for these tests';
    eval { require Hyperman; 1 }
        or plan skip_all => 'Hyperman required for the loop adapter';
}

{
    package DE::Model::Book;
    use Punk::Model;
    table 'books';
    field id    => { type => 'integer', primary => 1 };
    field title => { type => 'string', required => 1 };
    package DE::Model::Loose;
    use Punk::Model;
    table 'books';
    validate 0;
    field id    => { type => 'integer', primary => 1 };
    field title => { type => 'string' };
    package main;
}
my $dir = File::Temp->newdir;
my $dsn = "dbi:SQLite:dbname=$dir/books.db";
my %DB = (dsn => $dsn, workers => 1, backend => 'Punk::Model::DBIx::Loop', attr => { PrintError => 0 });

{
    my $e = '';
    eval { DE::Model::Book->_instantiate({ backend => 'Punk::Model::DBIx::Loop', workers => 1 })->backend->dbh; 1 } or $e = $@;
    like($e, qr/no dsn - add a database keyword/, 'a backend without a dsn is refused');
}

my $model = DE::Model::Book->_instantiate({ %DB });
$model->backend->dbh->do('CREATE TABLE books (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL)');
if (my $err = loop_pool_error($model)) {
    plan skip_all => "the async backend's pool could not fork here: $err";
}
my $be = $model->backend;
sub refuses {
    my ($re, $name, $code) = @_;
    my $e = '';
    eval { $code->(); 1 } or $e = $@;
    like($e, $re, $name);
}

{
    my $loose = DE::Model::Loose->_instantiate({ %DB });
    refuses(qr/create with no known columns/, 'a create naming no known column', sub { $loose->create({ colour => 'red' }) });
}
refuses(qr/update needs the primary key in the data/, 'an update without the key', sub { $model->update({ title => 'x' }) });
refuses(qr/update with no columns to change/, 'an update with nothing to change', sub { $model->update({ id => 1 }) });

my ($row) = $be->await($model->create({ title => 'first' }));
is($row->{title}, 'first', 'a create resolves to the stored row');

refuses(qr/future: need a DBIx::Loop::Future/, 'future() refuses what is not a DBIx::Loop future', sub { $be->future('nope') });
{
    my $f = $be->future($be->db->selectall_rowhash('SELECT * FROM books WHERE id = ?', 1));
    isa_ok($f, 'Punk::Future', 'future() bridges a raw query');
    my @got = $be->await($f);
    is($got[0][0]{title}, 'first', 'and the rows come through the bridge');
    is_deeply([ $be->await($f) ], [ @got ], 'awaiting a settled future returns its values again');
}
{
    require Punk::Future;
    my $pf = Punk::Future->new;
    my $loop = $be->adapter->loop;
    ok($loop, 'the adapter carries a loop of its own');
    $loop->defer(sub { $pf->done(42) });
    my @v = $be->await($pf);
    is($v[0], 42, 'await pumps the adapter loop until a plain future settles');
}

done_testing;
