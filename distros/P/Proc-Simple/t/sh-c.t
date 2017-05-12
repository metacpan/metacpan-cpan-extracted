#!/usr/bin/perl -w

use strict;
use Proc::Simple;
use Test::More;
use FindBin qw($Bin);

my $runfile = "$Bin/test-prog-running";

plan tests => 3;

unlink $runfile; # cleanup leftover from previous runs

my $psh  = Proc::Simple->new();

  # contains a wildcard, so will be launched via sh -c
$psh->start("$^X $Bin/bin/test-prog *");

while( ! $psh->poll() ) {
    # diag "waiting for process to start";
    sleep 1;
}

ok 1, "process is up";

  # wait for shell to spawn perl process
while( !-f $runfile ) {
    # diag "waiting for process to create runfile $runfile";
    sleep 1;
}

$psh->kill();

while( $psh->poll() ) {
    # diag "waiting for process to shut down";
    sleep 1;
}

ok 1, "process is down";

# as pointed out in [rt.cpan.org #69782], at this point, the grandchild
# might not have terminated yet or deleted the runfile, although its 
# parent (the shell process) is gone. Allow 10 seconds max.
for(1..10) {
    if( !-f "$Bin/test-prog-running" ) {
        last;
    }
    sleep 1;
}

ok !-f "$Bin/test-prog-running", "running file unlinked";

1;
