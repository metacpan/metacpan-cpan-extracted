#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Punk ();

# pk_abi's query observer, and the reach-through it used to miss.
#
# on_query was bolted to Punk::Model::DBI's six generated methods, which are a
# LAYER ABOVE the handle - so an application reaching $model->backend->dbh for
# an OR, a UNION, a FOR UPDATE or an upsert ran statements no observer could
# see, and nothing said so. Punk::DBI wraps the handle instead.

BEGIN {
    plan skip_all => 'DBD::SQLite required' unless eval { require DBD::SQLite; 1 };
}

is(Punk::_abi_selftest_install(), 1, 'the C selftest consumer registers');

{
    package T::Obs::Thing;
    use Punk::Model;
    table 'things';
    field id    => { type => 'integer', primary => 1 };
    field name  => { type => 'string' };
    field tally => { type => 'integer' };
}

my $model = T::Obs::Thing->_instantiate({ dsn => 'dbi:SQLite:dbname=:memory:' });
my $dbh   = $model->backend->dbh;

# ---- the handle took the subclass --------------------------------------------
is(ref($dbh), 'Punk::DBI::db',
    'with an observer registered the connection is a Punk::DBI handle');

$dbh->do('CREATE TABLE things (id INTEGER PRIMARY KEY, name TEXT, tally INTEGER)');

# (starts, dones, ok, nbind, sql) since load; the deltas are what matters.
sub counts { my @c = Punk::_abi_selftest_queries(); return @c }
sub since  {
    my ($code) = @_;
    my ($s0, $d0, $ok0) = counts();
    $code->();
    my ($s1, $d1, $ok1, $nbind, $sql) = counts();
    return { starts => $s1 - $s0, dones => $d1 - $d0, ok => $ok1 - $ok0,
             nbind => $nbind, sql => $sql };
}

# ---- the reach-through, which is the whole point ------------------------------
#
# Every one of these fails without Punk::DBI: DBI implements them in its own
# dispatch and they never reach the generated methods, so nothing observed them.
{
    $model->create({ name => 'one', tally => 1 });
    $model->create({ name => 'two', tally => 2 });

    my $r = since(sub {
        $dbh->selectall_arrayref('SELECT * FROM things WHERE tally > ?',
                                 { Slice => {} }, 0);
    });
    is($r->{starts}, 1, 'selectall_arrayref on the handle is observed');
    is($r->{dones},  1, 'and settles exactly once');
    is($r->{ok},     1, 'and is reported as having succeeded');
    like($r->{sql}, qr/SELECT \* FROM things/, 'with the statement text');
    is($r->{nbind}, 1, 'and the bind count, not the bind values');
    unlike($r->{sql}, qr/\bone\b/, 'the literal data never reaches an observer');

    $r = since(sub { $dbh->selectrow_array('SELECT name FROM things WHERE id = ?',
                                           undef, 1) });
    is($r->{starts}, 1, 'selectrow_array is observed');
    is($r->{nbind},  1, 'with its bind count');

    $r = since(sub { $dbh->selectrow_hashref('SELECT * FROM things WHERE id = ?',
                                             undef, 1) });
    is($r->{starts}, 1, 'selectrow_hashref is observed');

    $r = since(sub { $dbh->selectcol_arrayref('SELECT name FROM things') });
    is($r->{starts}, 1, 'selectcol_arrayref is observed');
    is($r->{nbind},  0, 'with no binds');

    $r = since(sub { $dbh->selectall_hashref('SELECT * FROM things WHERE id > ?',
                                             'id', undef, 0) });
    is($r->{starts}, 1, 'selectall_hashref is observed');
    is($r->{nbind},  1,
        'and its bind count accounts for the key field between sql and attr');

    $r = since(sub { $dbh->do('UPDATE things SET tally = ? WHERE id = ?', undef, 9, 1) });
    is($r->{starts}, 1, 'do is observed');
    is($r->{nbind},  2, 'with both binds counted');

    $r = since(sub { my $sth = $dbh->prepare('SELECT * FROM things WHERE id = ?');
                     $sth->execute(1); $sth->finish });
    is($r->{starts}, 1, 'an explicitly prepared statement is observed once');
}

# ---- once, not twice ----------------------------------------------------------
#
# The generated methods run prepare_cached + execute, which is now the st path.
# If the old firing site in pdbi_execute_sql had been left in place they would
# report twice, and every duration would be double counted.
{
    my $r = since(sub { $model->search({ tally => { '>' => 0 } }) });
    is($r->{starts}, 1, 'a generated method reports exactly once, not twice');
    is($r->{dones},  1, 'and settles once');

    $r = since(sub { $model->get(id => 1) });
    is($r->{starts}, 1, 'get reports once');

    $r = since(sub { $model->create({ name => 'three', tally => 3 }) });
    ok($r->{starts} >= 1, 'create reports');
    is($r->{dones}, $r->{starts}, 'and every start settled');
}

# ---- a statement that fails ---------------------------------------------------
{
    my ($s0, $d0, $ok0) = counts();
    eval { $dbh->do('SELECT * FROM nope') };
    ok($@, 'a broken statement still raises to the caller');
    my ($s1, $d1, $ok1) = counts();
    is($s1 - $s0, 1, 'it was observed');
    is($d1 - $d0, 1, 'it settled');
    is($ok1 - $ok0, 0, 'and was reported as having FAILED, not succeeded');
}

# ---- prepare_cached is not defeated by the subclass ---------------------------
{
    $dbh->prepare_cached('SELECT 1 FROM things', undef, 3);
    $dbh->prepare_cached('SELECT 1 FROM things', undef, 3);
    my $kids = $dbh->{CachedKids};
    ok($kids && keys %$kids, 'prepare_cached still caches under Punk::DBI');
    is(scalar(grep { /SELECT 1 FROM things/ } keys %$kids), 1,
        'and one statement handle per distinct SQL, not one per call');
}

# ---- an application that asked for its own RootClass keeps it -----------------
{
    {
        package T::Obs::Root;
        our @ISA = ('DBI');
        package T::Obs::Root::db;
        our @ISA = ('DBI::db');
        package T::Obs::Root::st;
        our @ISA = ('DBI::st');
    }
    # A DIFFERENT dsn on purpose. The connection pool keys on dsn, user and
    # password and not on attr (punk_dbi.h:110-113), so a second model on
    # ':memory:' would share the handle built above and prove nothing.
    my $file = File::Temp::tmpnam() . '.db';
    my $own = T::Obs::Thing->_instantiate({
        dsn  => "dbi:SQLite:dbname=$file",
        attr => { RootClass => 'T::Obs::Root' },
    });
    is(ref($own->backend->dbh), 'T::Obs::Root::db',
        "an application's own RootClass is never taken away from it");
    unlink $file;
}

done_testing;
