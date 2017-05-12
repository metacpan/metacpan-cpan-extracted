# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Parallel::Pvm::Scheduler') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $prm = new Parallel::Pvm::Scheduler();
ok ($prm);

my $hostcount = $prm->getHostCount();
ok($hostcount != 0);

my $freehosts = $prm->getFreeHostCount();
ok($freehosts == $hostcount);

#my $i;
#for ($i = 0; $i < $hostcount; $i++)
#{
#	my @args = ("/usr/bin/uptime");
#	$prm->submit("uptime $i", @args);
#}
#$prm->recaptureHosts(1);
#ok($hostcount == $prm->getFreeHostCount());

#for ($i = 0; $i < ($hostcount*2); $i++)
#{
#        my @args = ("/usr/bin/uptime");
#        $prm->submit("uptime $i", @args);
#}
#$prm->recaptureHosts(1);
#ok($hostcount == $prm->getFreeHostCount());
