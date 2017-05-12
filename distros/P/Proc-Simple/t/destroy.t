#!/usr/bin/perl -w

# Test the destructor code
# This test code has two parts:
# i) Fork a perl infinite loop
#    Retrieve the process id of the forked process
#    Undef the object
#    Try to kill the forked process

# ii)Fork a perl infinite loop
#    Retrieve the process id of the forked process
#    Set the kill_on_destroy flag
#    Undef the object
#    Try to kill the forked process

# In the first test the kill should succeed (since the process
# will still be running. In the second test the kill will fail
# since the destructor will have already killed the process.
# A sleep of 1 is inserted to make sure the kill signal arrives
# and the process shuts down before we check.
# We check the process is running by looking at the return
# value from perl kill.


use Proc::Simple;
use Test::More;

plan tests => 5;

###
### Simple Test of destroy
###

### Test code

$coderef = sub { while (1) { sleep(1) } };  # infinite loop

$psh  = Proc::Simple->new();

ok($psh->start($coderef));         # 1

# Retrieve the process id (so that we can look for it later)

my $pid = $psh->pid;

# Destroy object - process should still be running
undef $psh;

# Process should still be running - now kill it
# The sleep is here to make the test fair with the 
# ond_destroy test later
sleep 2;
ok($result = kill "SIGTERM", $pid);      # 2

ok($result == 1, "check result");        # 3
# print "Result should equal 1 if process was killed by us: $result\n";

# Now try the same thing with the kill_on_destroy flag set

$psh  = Proc::Simple->new();

ok($psh->start($coderef));         # 4

# Retrieve the process id (so that we can look for it later)

my $pid2 = $psh->pid;

# Set flag
$psh->kill_on_destroy(1);

# Destroy object - after that, process should terminate
undef $psh;

# Process should no longer be running
# The sleep makes sure that the process has died by the time
# we get there
$i = 0;
while($i++ < 10) {
    last unless kill 0, $pid2;
    sleep(1);
}

# Okay if we returned before the 10 secs expired
ok($i<10);
