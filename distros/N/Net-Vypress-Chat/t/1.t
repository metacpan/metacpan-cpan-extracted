# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'
# vim:syntax=perl

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 44;
#use Test::More 'no_plan';
BEGIN { use_ok('Net::Vypress::Chat') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $vyc = Net::Vypress::Chat->new(
	'send_info' => '0',
	'localip' => '127.0.0.1',
#	'localip' => '192.168.0.1',
#	'debug' => 1
);
ok(defined $vyc, '$vyc is an object');
ok($vyc->isa('Net::Vypress::Chat'), "and it's the right class");

# Startup stuff
$vyc->startup;
ok(defined $vyc->{'send'}, "send socket ok.");
ok(defined $vyc->{'usend'}, "unicast send socket ok.");
ok(defined $vyc->{'listen'}, "listen socket ok.");
ok($vyc->{'init'} eq '1', "module was initialized.");

# Testing functions
sub get_type_ok { # {{{
	my $oktype = shift;
	my ($buffer, $msgok);
	alarm 5;
	until ($msgok) {
		my @return = $vyc->readsock();
		my $type = shift @return;
		$msgok = 1 if ($type eq $oktype);
	}
	$msgok = 0 if $msgok == 2;
	return $msgok;
} # }}}
use Data::Dumper;

ok($vyc->num2status(0) eq "Available", "num2status avail. ok");
ok($vyc->num2status(1) eq "DND", "num2status DND ok");
ok($vyc->num2status(2) eq "Away", "num2status away ok");
ok($vyc->num2status(3) eq "Offline", "num2status offline ok");

ok($vyc->num2active(0) eq "Inactive", "num2active inactive ok");
ok($vyc->num2active(1) eq "Active", "num2active active ok");
ok($vyc->num2active(2) eq "Unknown", "num2active unknown ok");

$vyc->who();
ok(get_type_ok('who'), "got who.");

$vyc->join("#test");
ok($vyc->on_chan("#test") == 1, "join succeded.");

$vyc->remote_exec($vyc->{'nick'}, '', '');
ok(get_type_ok('remote_exec'), "got remote execution.");

$vyc->remote_exec_ack($vyc->{'nick'}, '');
ok(get_type_ok('remote_exec_ack'), "got remote execution ack.");

$vyc->sound_req("#Main", '');
ok(get_type_ok('sound_req'), "got sound req.");

$vyc->me("#Main", '');
ok(get_type_ok('me'), "got /me.");

$vyc->chat("#Main", '');
ok(get_type_ok('chat'), "got chat line.");

ok($vyc->on_chan("#bullies") == 0, "on_chan ok 0.");
ok($vyc->on_chan("#Main") == 1, "on_chan ok 1.");

$vyc->nick('anothernick');
ok($vyc->{'nick'} eq 'anothernick', "local nick change.");

$vyc->part("#test");
ok($vyc->on_chan("#test") == 0, "part succeded.");

$vyc->topic("#Main", 'Test topic.');
ok(get_type_ok('topic'), "got topic line.");

$vyc->status(0, "Available");
ok(get_type_ok('status'), "got avail. status change.");
$vyc->status(1, "DND");
ok(get_type_ok('status'), "got DND status change.");
$vyc->status(2, "Away");
ok(get_type_ok('status'), "got away status change.");
$vyc->status(3, "Offline");
ok(get_type_ok('status'), "got offline status change.");

$vyc->active(1);
ok(get_type_ok('active'), "got active change.");
$vyc->active(0);
ok(get_type_ok('active'), "got inactive change.");

$vyc->beep($vyc->{nick});
#ok(get_type_ok('beep'), "got beep.");

$vyc->info($vyc->{nick});
ok(get_type_ok('info'), "got info req.");

$vyc->info_ack($vyc->{nick});
ok(get_type_ok('info_ack'), "got info_ack.");

$vyc->info_ack($vyc->{nick}, "host", "user", "1.3.2.4", ['#Main', '#foobar']
	, "AA");
ok(get_type_ok('info_ack'), "got spoofed info_ack.");

ok($vyc->on_priv($vyc->{nick}) == 0, "on_priv not joined ok.");
$vyc->pjoin($vyc->{nick});
$vyc->pjoin($vyc->{nick}."aa");
ok($vyc->on_priv($vyc->{nick}) == 1, "pjoin ok.");

$vyc->pchat($vyc->{nick}, '');
#ok(get_type_ok('pchat'), "got pchat.");

$vyc->pme($vyc->{nick}, '');
#ok(get_type_ok('pme'), "got pme.");

$vyc->ppart($vyc->{nick});
ok($vyc->on_priv($vyc->{nick}) == 0, "ppart ok.");

$vyc->msg($vyc->{'nick'}, "");
ok(get_type_ok('msg'), "got msg.");

$vyc->mass_to(($vyc->{'nick'}), "");
ok(get_type_ok('mass'), "got mass_to.");

# Shutting down
$vyc->shutdown;
ok(!defined $vyc->{'send'}, "send socket shut down.");
ok(!defined $vyc->{'usend'}, "unicast send socket shut down.");
ok(!defined $vyc->{'listen'}, "listen socket shut down.");
ok($vyc->{'init'} eq '0', "module was uninitialized.");
