#!perl
use 5.006;
use strict;
use warnings;
use File::Temp qw(tempdir);
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# Exercises the real (non-testing) execution path via the shell backend:
# commands actually run, exit codes are checked, and failures raise the
# documented error codes. Everything else in the suite runs with testing => 1
# and never executes a command.

my $dir   = tempdir( CLEANUP => 1 );
my $state = $dir . '/state';

sub shell_fw {
	my (%options) = @_;
	return Net::Firewall::BlockerHelper->new(
		backend => 'shell',
		name    => 'derp',
		options => {
			init     => 'mkdir ' . $state,
			teardown => 'rm -rf ' . $state,
			ban      => 'touch ' . $state . '/%%%BAN%%%',
			unban    => 'rm ' . $state . '/%%%BAN%%%',
			check    => 'test -d ' . $state,
			%options,
		},
	);
}

# --- the success path actually runs the commands -----------------------------
{
	my $fw = shell_fw();
	$fw->init_backend;
	ok( -d $state, 'init really ran and created the state dir' );

	is( $fw->check, 1, 'check reports healthy while the state dir exists' );

	$fw->ban( ban => '1.2.3.4' );
	ok( -f $state . '/1.2.3.4', 'ban really ran and created the ban file' );

	$fw->unban( ban => '1.2.3.4' );
	ok( !-f $state . '/1.2.3.4', 'unban really ran and removed the ban file' );

	# flush without a flush command falls back to unbanning each banned IP
	$fw->ban( ban => '1.2.3.4' );
	$fw->ban( ban => '5.6.7.8' );
	$fw->flush;
	ok( !-f $state . '/1.2.3.4' && !-f $state . '/5.6.7.8', 'flush fallback really unbanned each IP' );
	is( scalar( $fw->list ), 0, 'flush fallback emptied the ban list' );

	$fw->teardown;
	ok( !-d $state, 'teardown really ran and removed the state dir' );

	is( $fw->check, 0, 'check reports unhealthy once the state dir is gone' );
}

# --- a configured flush command is used instead of the fallback --------------
{
	my $fw = shell_fw( flush => 'rm -f ' . $state . '/*' );
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	$fw->flush;
	ok( !-f $state . '/1.2.3.4', 'configured flush command really ran' );
	is( scalar( $fw->list ), 0, 'configured flush emptied the ban list' );
	$fw->teardown;
}

# --- self-heal end to end: externally wiped setup is rebuilt with its bans ---
{
	my $fw = shell_fw();
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );

	# something external wipes the setup out from under us
	system( 'rm', '-rf', $state );
	ok( !-d $state, 'setup externally wiped' );
	is( $fw->check, 0, 'check notices the externally wiped setup' );

	# the next ban self-heals: re_init rebuilds the setup and re-bans 1.2.3.4
	$fw->ban( ban => '5.6.7.8' );
	ok( -d $state,               'self-heal rebuilt the setup before banning' );
	ok( -f $state . '/1.2.3.4',  'self-heal re-banned the previously banned IP' );
	ok( -f $state . '/5.6.7.8',  'the new ban landed after the self-heal' );

	# with self_heal disabled per call, a wipe is not repaired and the ban fails
	system( 'rm', '-rf', $state );
	eval { $fw->ban( ban => '9.8.7.6', self_heal => 0 ); };
	ok( $@, 'ban with self_heal disabled fails on the wiped setup' );
	is( $fw->error, 13, 'the failed ban raised error 13' );
	ok( !-d $state, 'self_heal=0 really skipped the repair' );

	system( 'mkdir', $state );
	$fw->teardown;
}

# --- self-heal survives a teardown command that fails on the wiped setup -----
# re_init treats teardown as best effort; with a strict teardown command like
# rmdir (which fails when the dir is already gone) the heal must still work
{
	my $fw = shell_fw( teardown => 'rmdir ' . $state );
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );

	system( 'rm', '-rf', $state );
	$fw->ban( ban => '5.6.7.8' );
	ok( -d $state, 'self-heal rebuilt the setup even though teardown of the wiped setup fails' );
	ok( -f $state . '/1.2.3.4', 'the previous ban was re-added despite the failing teardown' );
	ok( -f $state . '/5.6.7.8', 'the new ban landed despite the failing teardown' );

	system( 'rm', '-rf', $state );
}

# --- failure paths raise the documented error codes ---------------------------
{
	my $fw;
	eval {
		$fw = shell_fw( init => 'false' );
		$fw->init_backend;
	};
	ok( $@, 'a failing init command makes init_backend die' );
	is( $Error::Helper::error, 12, 'a failing init command raises error 12' );
}
{
	my $fw = shell_fw( ban => 'false' );
	$fw->init_backend;
	eval { $fw->ban( ban => '1.2.3.4' ); };
	ok( $@, 'a failing ban command dies' );
	is( $fw->error, 13, 'a failing ban command raises error 13' );
	$fw->teardown;
}
{
	my $fw = shell_fw( unban => 'false' );
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	eval { $fw->unban( ban => '1.2.3.4' ); };
	ok( $@, 'a failing unban command dies' );
	is( $fw->error, 14, 'a failing unban command raises error 14' );
	$fw->teardown;
}
{
	my $fw = shell_fw( flush => 'false' );
	$fw->init_backend;
	$fw->ban( ban => '1.2.3.4' );
	eval { $fw->flush; };
	ok( $@, 'a failing flush command dies' );
	is( $fw->error, 25, 'a failing flush command raises error 25' );
	$fw->teardown;
}
{
	my $fw = shell_fw( teardown => 'false' );
	$fw->init_backend;
	eval { $fw->teardown; };
	ok( $@, 'a failing teardown command dies' );
	is( $fw->error, 17, 'a failing teardown command raises error 17' );
	system( 'rm', '-rf', $state );
}

done_testing();
