# 06-LockFile.t - unit test

# If you have any questions about this software,
# or need to report a bug, please contact me.
# 
# Matt Luker
# Port Angeles, WA
# mluker@rshtech.com
# 
# TTGOG

use strict;
use warnings;

use Test::More tests => 13;

use Net::Domain qw(hostname hostfqdn hostdomain);

BEGIN { use_ok('RSH::LockFile') };


my $test_filename = "testfile.txt";

my $lock = undef;

$lock = new RSH::LockFile $test_filename;
unlink $lock->lock_filename;

my $exception;
SKIP: {
    skip "old lock file still persists, can't test locking", 6 unless (not -e $lock->lock_filename);
    eval {
        $lock->lock;
    };
    $exception = $@;
    ok((not $exception), "locked correctly");
    diag($exception) if $exception;
    ok((-e $lock->lock_filename), "lock file exists");
    open LOCK_FILE, "<". $lock->lock_filename;
    my $val = <LOCK_FILE>;
    ok(($val eq $$), "lock file contents should be process id");
    eval {
        $lock->lock;
    };
    $exception = $@;
    ok($exception, "lock on existing lock fails");
    diag($exception) if $exception;
    eval {
        $lock->unlock;
    };
    $exception = $@;
    ok((not $exception), "unlocked correctly");
    diag($exception) if $exception;
    ok((not -e $lock->lock_filename), "lock file removed correctly");
    unlink $lock->lock_filename; # just to be sure ...
};

$lock = new RSH::LockFile $test_filename, 'net_fs_safe' => 1;
unlink $lock->lock_filename;

SKIP: {
    skip "old lock file still persists, can't test locking", 6 unless (not -e $lock->lock_filename);
    eval {
        $lock->lock;
    };
    $exception = $@;
    ok((not $exception), "locked correctly");
    diag($exception) if $exception;
    ok((-e $lock->lock_filename), "lock file exists");
    open LOCK_FILE, "<". $lock->lock_filename;
    my $val = <LOCK_FILE>;
    my $id = hostfqdn();
    $id .= "-";
    $id .= $$;
    ok(($val eq $id), "lock file contents should be $id");
    eval {
        $lock->lock;
    };
    $exception = $@;
    ok($exception, "lock on existing lock fails");
    diag($exception) if $exception;
    eval {
        $lock->unlock;
    };
    $exception = $@;
    ok((not $exception), "unlocked correctly");
    diag($exception) if $exception;
    ok((not -e $lock->lock_filename), "lock file removed correctly");
    unlink $lock->lock_filename; # just to be sure ...
};

exit 0;

# ------------------------------------------------------------------------------
#  $Log$
# ------------------------------------------------------------------------------