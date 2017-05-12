# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use Proc::Wait3;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $childpid = fork();

if ($childpid == 0)
{
    sleep 1;
    exit 0;
}

print "Forked child $childpid\n";

my ($pid, $status, @resources) = wait3(1);

print "PID = [$pid], STATUS = [$status]\n";
print "Resources: ", join(',', @resources), "\n";

ok(2);
