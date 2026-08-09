#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PQTest;

plan skip_all => 'DBI and DBD::SQLite required' unless has_dbd();

# The multi-process lock races the battery cannot run in one process.
# Forked contenders, no coordination beyond the database - the unique
# index (lease) and the serialised count (counted) must each admit
# exactly the right number of winners.

my $CONTENDERS = 8;

sub race {
    my ($file, $name, %lock_opts) = @_;
    my %pipes;
    for my $n (1 .. $CONTENDERS) {
        pipe my $r, my $w or die "pipe: $!";
        my $pid = fork // die "fork: $!";
        if (!$pid) {
            close $r;
            require Punk::Queue;
            my $q = Punk::Queue->new(dsn => "dbi:SQLite:dbname=$file");
            my $got = $q->lock($name, 60, owner => $n, %lock_opts);
            print {$w} ($got ? 1 : 0), "\n";
            close $w;
            # _exit semantics via POSIX to skip the parent's END blocks
            require POSIX;
            POSIX::_exit(0);
        }
        close $w;
        $pipes{$pid} = $r;
    }
    my $winners = 0;
    for my $pid (keys %pipes) {
        my $r = $pipes{$pid};
        my $line = <$r> // '';
        chomp $line;
        $winners += $line ? 1 : 0;
        close $r;
        waitpid $pid, 0;
    }
    return $winners;
}

# the lease: eight contenders, exactly one winner
{
    my ($q, $file) = make_queue();
    is(race($file, 'leader'), 1,
       'lease: exactly one of eight forked contenders won');
    is($q->list_locks(0, 0, { name => 'leader' })->{total}, 1,
       'and exactly one row exists');
}

# counted, limit 3: exactly three winners
{
    my ($q, $file) = make_queue();
    is(race($file, 'slots', limit => 3), 3,
       'counted: exactly three of eight won');
    is($q->list_locks(0, 0, { name => 'slots' })->{total}, 3,
       'and exactly three rows exist');
}

# repeatedly, because races pass by luck once
for my $round (1 .. 3) {
    my ($q, $file) = make_queue();
    is(race($file, 'again'), 1, "round $round: still exactly one winner");
}

done_testing();
