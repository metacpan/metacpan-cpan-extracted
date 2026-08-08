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
    eval { require DBIx::Loop; 1 }
        or plan skip_all => 'DBIx::Loop required for these tests';
}

# Per-worker isolation for the async backend: a forked child must get its own
# DBIx::Loop (its own pool workers, its own adapter), never the parent's -
# sharing would have two processes reading one socketpair, so one process
# could receive the other's rows. The pid guard in punk_dbil.h and
# DBIx::Loop 0.02's own disown logic each enforce this; here it is asserted
# through the model tier, the way an application actually hits it.

{
    package T::Model::Row;
    use Punk::Model;
    table 'rows';
    field id => { type => 'integer', primary => 1 };
    field v  => { type => 'string' };
}

my $dir = File::Temp->newdir;
my $dsn = "dbi:SQLite:dbname=$dir/rows.db";

my $model = T::Model::Row->_instantiate({
    dsn => $dsn, workers => 2, backend => 'Punk::Model::DBIx::Loop' });
$model->backend->dbh->do(
    'CREATE TABLE rows (id INTEGER PRIMARY KEY, v TEXT)');

# force the pool up in the parent, and seed rows the children will read
$model->create({ id => 1, v => 'parent' })->get;
$model->create({ id => $_ + 10, v => "child$_" })->get for 1 .. 3;

my @parent_pids = $model->backend->db->_worker_pids;
is(scalar @parent_pids, 2, 'the parent pool forked its workers');

# ---- children see their own rows through their own pools --------------------
my @kids;
for my $i (1 .. 3) {
    my $pid = open my $rd, '-|';
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        # the first statement in the child must build a fresh backend handle
        my ($row) = $model->get(id => $i + 10)->get;
        my @pids = $model->backend->db->_worker_pids;
        print join(',', @pids), "\n";
        print $row->{v} // '(undef)', "\n";
        exit 0;
    }
    push @kids, [ $i, $rd ];
}

my %parent = map { $_ => 1 } @parent_pids;
for my $k (@kids) {
    my ($i, $rd) = @$k;
    chomp(my @out = <$rd>);
    close $rd;
    my @child_pids = split /,/, ($out[0] // '');
    is(scalar(grep { $parent{$_} } @child_pids), 0,
       "child $i forked its own workers, none of them the parent's");
    is($out[1], "child$i", "and read only its own row");
}

# ---- the parent survived them -----------------------------------------------
my @still = $model->backend->db->_worker_pids;
is_deeply([ sort { $a <=> $b } @still ], [ sort { $a <=> $b } @parent_pids ],
          'the parent still has the same workers after every child exited');
is(scalar(grep { kill(0, $_) } @still), scalar @still,
   'and every one of them is still running');

my ($p) = $model->get(id => 1)->get;
is($p->{v}, 'parent', 'and the parent can still query');

done_testing();
