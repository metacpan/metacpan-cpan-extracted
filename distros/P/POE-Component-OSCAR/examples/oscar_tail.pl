#!/usr/bin/perl

# This sample script will IM lines from a tailed file to $SEND_TO_SCREENNAME.

use strict;
use POE qw(Wheel::FollowTail Component::OSCAR);

my ($oscar);

# create a screenname for your script at http://www.aim.com
my $MY_SCREENNAME = 'A SCREENNAME';
my $MY_PASSWORD = 'A PASSWORD';

# all messages will be sent to:
my $SEND_TO_SCREENNAME = 'A SCREENNAME';

my $FILE_TO_TAIL = 'A FILENAME';

# only send errors matching these regular expressions (leave blank to send all
# lines)
my @ALLOW_REGEXES = ( qr/ERROR/ );

# ignore lines matching these regular expressions (leave blank to send all
# lines)
my @IGNORE_REGEXES = ( qr/mail/ );

POE::Session->create(
	package_states => [
		main => [qw(_start _stop im_in signon_done tail_in tail_error tail_reset)]
	]
);
$poe_kernel->run();

sub _start {
	# start the Oscar module with a throttle time of 4 second
	$oscar = POE::Component::OSCAR->new( throttle => 4 );

	# Oscar's 'signon_done' callback will call our state, 'signon_done', etc.
	# See the Net::OSCAR docs for all the possible callbacks
	$oscar->set_callback( signon_done => 'signon_done' );
	$oscar->set_callback( im_in => 'im_in' );
	$oscar->set_callback( error => 'error' );
	$oscar->set_callback( admin_error => 'admin_error' );
	$oscar->set_callback( rate_alert => 'rate_alert' );

	$oscar->loglevel( 5 );

	$oscar->signon( screenname => $MY_SCREENNAME, password => $MY_PASSWORD );
}

sub signon_done {
	print "Signon done!\n";

	# start tailing the file
	HEAP->{wheel} = POE::Wheel::FollowTail->new(
		Filename => $FILE_TO_TAIL,
		Driver	 => POE::Driver::SysRW->new(),
		Filter	 => POE::Filter::Line->new(),
		PollInterval => 1,
		InputEvent => 'tail_in',
		ErrorEvent => 'tail_error',
		ResetEvent => 'tail_reset',
	);
}

sub tail_in {
	my $msg = $_[ARG0];

	for my $regex (@IGNORE_REGEXES) {
		if ($msg =~ /$regex/) {
			return;
		}
	}

	for my $regex (@ALLOW_REGEXES) {
		if ($msg =~ /$regex/) {
			print "Sending to $SEND_TO_SCREENNAME: $msg\n";
			$oscar->send_im( $SEND_TO_SCREENNAME => $msg );
			return;
		}
	}

}

sub tail_error {
	my ($operation, $errnum, $errstr, $wheel_id) = @_[ARG0..ARG3];
	warn "Wheel $wheel_id generated $operation error $errnum: $errstr\n";
};

sub tail_reset {
	warn "File reset";
}

sub im_in {
	# first arg is empty; see the Net::OSCAR module for details about
	# the other arguments
	my $args = $_[ARG1];
	my ($object, $who, $what, $away) = @$args;

	print "Received from $who: $what\n";
}

sub error {
	my $args = $_[ARG1];
	my ($object, $connection, $error, $description, $fatal) = @$args;
	warn("ERROR: $error / $description / $fatal");
}

sub admin_error {
	my $args = $_[ARG1];
	my ($object, $reqtype, $error, $errval) = @$args;
	warn("ADMIN ERROR: $reqtype / $error / $errval");
}

sub rate_alert {
	my $args = $_[ARG1];
	my ($object, $level, $clear, $window, $worrisome) = @$args;
	warn("RATE ALERT: $level / $clear / $window / $worrisome");
}

sub _stop {
}
