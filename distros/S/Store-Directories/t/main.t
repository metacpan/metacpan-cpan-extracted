use strict;
use warnings;

use Config;
use Cwd qw(abs_path);
use Time::HiRes qw(sleep);
use Test::More  tests => 432;
use Test::Cmd;

use DBI;

use Store::Directories;

my $arch_ok = ( $Config{archname} =~ /linux/i )
    or BAIL_OUT("Store::Directories is for Linux ONLY");
ok($arch_ok, "Running Linux");

# Set up workdin directory/test environment
my $testenv = Test::Cmd->new(workdir => '');
my $builder = Test::More->builder;
$builder->use_numbers(0);
$builder->no_ending(1);


# Create Store
my $storedir = $testenv->workdir."/store";
my $store = Store::Directories->init($storedir);
isa_ok($store, "Store::Directories");
is($store->path, $testenv->workdir."/store", "Store has correct path.");

# Test that database exists and its been init'ed with the right info
my $dbh = DBI->connect(
    "dbi:SQLite:dbname=".$store->{dbfile},
    "", "",
    { PrintError => 0,  AutoCommit => 1, AutoInactiveDestroy => 1 }
);
die "Could not connect to database." unless $dbh;
my $tables = $dbh->selectall_hashref(<<END, 'name');
SELECT name FROM sqlite_master WHERE
    type = 'table' AND
    name NOT LIKE 'sqlite_%'
END
die $dbh->errstr if $dbh->err;
my $tables_ok = (exists $tables->{entry} && exists $tables->{lock})
    or BAIL_OUT("Database could not be initialized.");
ok($tables_ok, "Database Initialized");
$dbh->disconnect;

# Conduct simulataneous tests for 5 different keys
# (405 tests)
my @testkeys = qw'foo bar baaz quux blarg';
my $waiting = 0;
for my $testkey (@testkeys) {
    my $pid = fork;
    die "unable to fork: $!" unless defined $pid;
    
    if ($pid == 0) {
        $testenv->preserve;
        eval { big_test($testkey); 1 } or exit 1;
        exit 0;
    }

    $waiting++;
}

# Reap children
while ($waiting) {
    wait;
    $waiting--;
}

# Test that get_listing works
# (6 tests)
my %listing = %{$store->get_listing};
is(scalar(keys %listing), scalar(@testkeys), "Correct number of entries");
while (my ($key, $dir) = each %listing) {
    ok(-d $dir, "Directory '$key' exists.");
}

# Remove each test directory after confirming they have
# the correct value
# (10 tests)
for my $testkey (@testkeys) {
    my $lock;
    my $dir = $store->get_or_add($testkey, {lock_ex => \$lock} );
    $store->remove($testkey, sub {
        my $value = read_file_in_dir($dir);
        is($value, 10, "Value in directory '$testkey' is correct");
    });
    # Confirm that the directory has been removed
    ok( !(-d $dir), "Directory '$testkey' is gone" );
}

# Test high-level methods
# (7 tests)
my $testdir = $store->get_or_add('foo');
$store->run_in_dir('foo', \&init_dir);
my $val = $store->get_in_dir('foo', \&read_file_in_dir);
is($val, 0, "run_in_dir and get_in_dir work");

fork_workers(5, \&do_get_or_set_entry, 'foo', 3);
$val = $store->get_in_dir('foo', \&read_file_in_dir);
is($val, 3, "get_or_set works");

#
# Helper Functions
#

# big_test KEY
# Spawns 5 simultaneous workers to create/increment a file in the directory
# with KEY, then spawns some workers to read the value, then spawns 5 more
# workers to increment.
# (81 tests)
sub big_test {
    my $key = shift;

    # First batch of increments
    # (25 tests)
    fork_workers( 5, \&do_increment_entry, $key);

    # Get a shared lock
    my $sh = $store->lock_sh($key);

    # Fork another batch of increments, but these should block
    # unitl we release the shared lock
    my $increment_pid = fork;
    die "unable to fork: $!" unless defined $increment_pid;

    if ($increment_pid == 0) {
        # Child
        # (25 tests)
        $testenv->preserve;
        eval { fork_workers(5, \&do_increment_entry, $key); 1 } or exit 1;
        exit 0;
    }

    # Wait a bit
    sleep 0.1;

    # Spawn some workers to verify the counter value (these should work
    # because they use shared locks)
    # (15 tests)
    fork_workers(3, \&do_check_entry, $key, 5);

    # Release shared lock then wait on next increment workers
    $sh->DESTROY;
    waitpid($increment_pid, 0);

    # Test that they succeeded
    # (1 test)
    is($? >> 8, 0, "Increment workers successful");

    # One more round to check the counter (which should be 10 now)
    # (15 tests)
    fork_workers(3, \&do_check_entry, $key, 10);

}

# fork_workers NUM SUB [ARGS]
# Create NUM forks which each execute SUB with arguments ARGS. Waits for
# all forks to finish before retruning, then runs one test for each fork
# checking that it exited without error.
# Each fork chdir's into the workdir
sub fork_workers {
    my $num = shift;
    my $sub = shift;
    my @args = @_;

    # Create children
    my %exit_codes;
    my $waiting = 0;
    for (1..$num) {
        my $pid = fork;
        die "unable to fork: $!" unless defined $pid;

        if ($pid == 0) {
            # Child
            $testenv->preserve;
            chdir($testenv->workdir);
            eval { $sub->(@args); 1 } or exit 1;
            exit 0;
        }
        $waiting++;
        $exit_codes{$pid} = -1;
    }

    # Reap children
    while ($waiting) {
        my $pid = wait;
        if ($exit_codes{$pid} == -1 ) {
            # Got a child
            $waiting--;
            $exit_codes{$pid} = $? >> 8;
            is($exit_codes{$pid}, 0, "Proc ($$) exited successfully.");
        }
    }
}

# do_get_or_set_entry KEY MAX
# (To be called in a forked child). Uses the get_or_set method to
# increment the file in the directory with KEY, but only if its value
# is below MAX
sub do_get_or_set_entry {
    my ($key, $max) = @_;

    my $st = Store::Directories->init("store");

    $st->get_or_set($key,
        # GET
        sub {
            my $val = read_file_in_dir(shift);
            return undef if $val < $max;
        },
        # SET
        \&increment_file_in_dir
    );
}

# do_check_entry KEY COUNT
# (To be called in a forked child). Init a new Store object, checkout
# a directory with KEY (with a shared lock), and test that the value
# in the counter file matches COUNT
# Conducts 4 tests
sub do_check_entry {
    my ($key, $count) = @_;

    my $st = Store::Directories->init("store");

    my $lock;
    my $dir = $st->get_or_add($key, {
        lock_sh => \$lock,
        init    => \&init_dir
    });

    isa_ok($lock, "Store::Directories::Lock");
    isnt($lock->exclusive, 1, "Lock is shared");

    my $locks = $st->get_locks($key);
    isnt($locks->{$$}, 1, "Proc ($$) has shared lock.");

    my $value = read_file_in_dir($dir);
    is($value, $count, "Value in file = $count");
}

# do_increment_entry KEY
# (To be called in a forked child). Init a new Store object, checkout
# a directory with KEY, and increment the file inside it.
# Conducts 4 tests
sub do_increment_entry {
    my $key = shift;
    my $st  = Store::Directories->init("store");

    my $lock;
    my $dir = $st->get_or_add($key, {
        lock_ex => \$lock,
        init    => \&init_dir
    });


    isa_ok($lock, "Store::Directories::Lock");
    ok($lock->exclusive, "Lock is exclusive");

    my $locks = $st->get_locks($key);
    ok($locks->{$$}, "Proc ($$) has exclusive lock.");
    is(scalar(keys %$locks), 1, "No other process has locks.");

    increment_file_in_dir($dir);
    1;
}

# init_dir DIR
# Used as the init callback to $store->get_or_add.
# Create a file counter.txt with the text "0\n" in it.
sub init_dir {
    use autodie qw(:file);
    my $dir = shift;
    my $file = "$dir/counter.txt";

    open(my $fh, '>', $file);
    print $fh "0\n";
    close $fh;
}

# read_file_in_dir DIR
# Looks for a file DIR/counter.txt, reads it and returns the number
# inside
sub read_file_in_dir {
    use autodie qw(:file);
    my $dir = shift;
    my $file = "$dir/counter.txt";

    open(my $fh, '<', $file);
    chomp(my $value = <$fh>);
    close $fh;
    return $value;
}

# increment_file_in_dir DIR
# Looks for a file DIR/counter.txt, reads it, increments the number
# inside and writes back to it
sub increment_file_in_dir {
    use autodie qw(:file);
    my $dir = shift;
    my $file = "$dir/counter.txt";

    open(my $fh, '<', $file);
    chomp(my $value = <$fh>);
    sleep 0.1; # sleeping makes it likely that a race condition will occur
               # if it's possible. We're testing that it's not possible
    $value++;
    open($fh, '>', $file);
    print $fh "$value\n";
    close $fh;
}

