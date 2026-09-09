#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use Time::HiRes ();
use Punk ();

# The file store's single-flight lock, and the two ways it used to lie.
#
# The lock is a file, and its holder is judged still alive by that file's
# age. The age came from st_mtime, which is a whole number of seconds: a
# lock written at 100.9 reports 100, so a tenth of a second later its age
# reads as a full second. Any lock_wait under a second was therefore spent
# before it began - the lock was stolen almost at once, at random, and two
# callers computed the same thing while both believed they held it.
#
# Nothing caught it because the tests that exercise a short lock_wait assert
# that the loser executes ANYWAY once the budget runs out, which is the same
# outcome. This file asserts the part that differs: that the budget has to
# actually elapse first.

my $root = File::Temp->newdir;
my $n    = 0;
sub fresh { Punk::Cache::File->new(dir => "$root/c" . $n++, @_) }

# ---- a sub-second budget is not spent the moment it is taken ----------------
{
    my $c = fresh(lock_wait => 0.3);

    is($c->_lock('k'), 1, 'the first caller takes the lock');
    is($c->_lock('k'), 0,
       'and a second caller is told to look again - IMMEDIATELY after, which '
     . 'is where whole-second mtime used to report the lock as a second old '
     . 'and steal it');

    # Hammer it for well under the budget. Every one of these must lose:
    # a single steal here is the bug, and one that only shows up on the
    # fraction of runs that start late in a second.
    my $stolen = 0;
    my $end = Time::HiRes::time() + 0.2;
    while (Time::HiRes::time() < $end) {
        $stolen++ if $c->_lock('k');
        Time::HiRes::sleep(0.005);
    }
    is($stolen, 0, 'and stays held for the whole budget, every attempt');
}

# ---- but a lock older than the budget is still stolen ------------------------
# The other half of the contract: the steal exists so one crashed holder does
# not poison a key until somebody notices. Widening the age must not have
# turned the steal off.
{
    my $c = fresh(lock_wait => 0.2);
    is($c->_lock('k'), 1, 'taken');

    # PCF_MTIME_SLACK adds a second to the budget where the platform has no
    # sub-second mtime, so wait past that too rather than asserting a bound
    # this machine may not meet.
    my $won = 0;
    my $end = Time::HiRes::time() + 5;
    while (Time::HiRes::time() < $end) {
        last if $won = $c->_lock('k');
        Time::HiRes::sleep(0.02);
    }
    ok($won, 'a lock left behind by a holder that never came back is stolen');
}

# ---- unlock releases it ------------------------------------------------------
{
    my $c = fresh(lock_wait => 30);
    is($c->_lock('k'), 1, 'taken');
    is($c->_lock('k'), 0, 'held');
    $c->_unlock('k');
    is($c->_lock('k'), 1, 'and free again once the holder unlocks');
}

# ---- the lock is per key -----------------------------------------------------
{
    my $c = fresh(lock_wait => 30);
    is($c->_lock('one'), 1, 'one key taken');
    is($c->_lock('two'), 1, 'another key is a different lock');
    is($c->_lock('one'), 0, 'and the first is still held');
}

# ---- locks that could not be attempted are counted --------------------------
# A path that will not form used to answer 1, which reads as "you won" - so
# every caller was told to compute and the herd ran unprotected, silently.
# The count is what makes that visible; it is zero on a store that works.
{
    my $c = fresh(lock_wait => 30);
    $c->_lock('k');
    my %s = $c->stats;
    ok(exists $s{lock_errors}, 'the file store reports lock_errors');
    is($s{lock_errors}, 0, 'and it is zero when every lock could be tried');
}

done_testing;
