#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use POE;

# call POE run prior to creating any sessions for the purpose of avoiding warning messages
# see https://metacpan.org/pod/POE::Kernel
POE::Kernel->run();

BEGIN {
	use_ok('POE::Wheel::Run::DaemonHelper') || print "Bail out!\n";
}

my $worked = 0;
eval {

	my $program = 'sleep 1; echo test; derp derp derp';

	# some non-default values to init it with for testing purposes
	my $expected = {
		program            => $program,
		status_syslog      => 2,
		restart_ctl        => 0,
		status_print       => 2,
		status_print_warn  => 2,
		status_syslog_warn => 2,
		syslog_name        => 'test1',
		syslog_facility    => 'mail',
		initial_delay      => 3,
		stderr_prepend     => 'test2',
		stdout_prepend     => 'test3',
		max_delay          => 45,
		status_syslog      => 0,
	};

	# init it with non standard defaults to make sure it can
	my $dh = POE::Wheel::Run::DaemonHelper->new( %{$expected} );

	my @test_keys = keys( %{$expected} );
	foreach my $key (@test_keys) {
		if ( !defined( $dh->{$key} ) ) {
			die( $key . ' expected to be ' . $expected->{$key} . ' but .$dh->{' . $key . '} is undef' );
		} elsif ( $expected->{$key} ne $dh->{$key} ) {
			die( $key . ' expected to be ' . $expected->{$key} . ' but "' . $dh->{$key} . '" found' );
		}
	}

	# try to create a POE session
	$dh->create_session;

	# make sure log_message does not die
	$dh->log_message( status => 'test' );
	$dh->log_message( error  => 1, status => 'test warning log message' );

	$worked = 1;
};
ok( $worked eq '1', 'early' ) or diag( "early test died with ... " . $@ );

done_testing(2);
