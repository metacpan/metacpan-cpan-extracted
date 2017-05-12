package POE::Component::OSCAR;

use 5.006;
use strict;
use vars qw($VERSION);
use Filter::Template;
use POE 0.28;

$VERSION = .05;

# make life prettier
const KERNEL    $_[KERNEL]
const HEAP      $_[HEAP]
const SESSION   $_[SESSION]
const OBJECT    $_[OBJECT]
const ARGS      @_[ARG0..$#_]
const SENDER    $_[SENDER]

# Create an object skeleton to make code in the calling app prettier
sub new {
	my $class = shift;
	my @args = @_;

	my $self = {
		session => POE::Session->create(
			package_states => [
				OSCARSession => [qw(_start _stop _default queue_im rd_ok wr_ok ex_ok set_callback connection_changed quit)]
			],
			args => [ @args ],
		)
	};

	bless $self, $class;

	return $self;
}

# Pass $oscar->anymethod calls to the anymethod state of the POE
# session, which will get picked up by _default and passed to the
# Net::OSCAR object
sub AUTOLOAD {
	my $self = shift;

	use vars qw($AUTOLOAD);
	my $state = $AUTOLOAD;
	$state =~ s/.*:://;
	$poe_kernel->post( $self->{session} => $state => @_ );
}

package OSCARSession;

use POE;
use Net::OSCAR 0.62;
use Time::HiRes qw(sleep time);

# store filenos so if we get a new one, we can have POE watch it
my %filenos = ();

sub _start {
	my %args = ARGS;

	KERNEL->sig( INT => 'quit' );
	HEAP->{throttle_time} = delete $args{throttle};
	HEAP->{im_queue} = [];

	my $oscar = HEAP->{oscar} = Net::OSCAR->new( %args );
#	$oscar->loglevel( 10, 1 );

	$oscar->set_callback_connection_changed( SESSION->callback( 'connection_changed' ) );
}

sub rd_ok {
	my ($socket) = ARGS;
	my $fileno = fileno($socket);
	return unless $fileno;
	my $conn = HEAP->{oscar}->findconn($fileno);
	sleep 0.1;
	$conn->process_one(1, 0);
}

sub wr_ok {
	my ($socket) = ARGS;
	my $fileno = fileno($socket);
	return unless $fileno;
	my $conn = HEAP->{oscar}->findconn($fileno);
	sleep 0.1;
	$conn->process_one(0, 1);
}

sub ex_ok {
	my ($socket) = ARGS;
	my $fileno = fileno($socket);
	return unless $fileno;
	my $conn = HEAP->{oscar}->findconn($fileno);
	KERNEL->select($socket); # stop POE from watching the socket
	$conn->{sockerr} = 1;
	$conn->disconnect();
	sleep 0.1;
}

sub _stop {
}

sub queue_im {
	my @send_im_args = ARGS;

	my $queue = HEAP->{im_queue};
	if (@send_im_args) {
		push @$queue, \@send_im_args;
	}

	if (@$queue and HEAP->{last_im_sent_time} + HEAP->{throttle_time} < time) {
		my $args = shift @$queue;
		eval {
			HEAP->{oscar}->send_im( @$args );
		};
		warn $@ if $@;

		HEAP->{last_im_sent_time} = time;

	} else {
		KERNEL->delay( "queue_im",
			HEAP->{last_im_sent_time} + HEAP->{throttle_time} - time );
		return;
	}

	if (@$queue) {
		KERNEL->delay( "queue_im", HEAP->{throttle_time} );
	}
}

sub _default {
	my ($method, $args) = ARGS;

	if ($method eq 'send_im' and HEAP->{throttle_time}) {
		KERNEL->yield( "queue_im", @$args );
		return;
	}

	eval {
		HEAP->{oscar}->$method( @$args );
	};
	warn $@ if $@;
}

sub quit {
	exit;
}

sub set_callback {
	my ($callback, $state) = ARGS;

	my $method = "set_callback_${callback}";
	HEAP->{oscar}->$method( SENDER->postback( $state ) ); 
}

# Net::OSCAR will send us one of four states when a connection's
# state changes: read, write, readwrite, and deleted.  Unfortunately,
# "connected" is not one of these, so when we see anything other than
# a "deleted", we check %filenos to see if POE is already watching it.
# If not, we ask POE to watch it.
sub connection_changed {
	my @args = ARGS;
	my ($oscar_obj, $connection, $state) = @{$args[1]};

	my $socket = $connection->{socket};
	if ($state eq 'deleted') {
		delete $filenos{ fileno($socket) };
		$poe_kernel->select( $socket );
	} elsif (!$filenos{ fileno($socket) }) {
		# Need the line below for faster machines; otherwise some bits seem to get lost
		# along the way.  It's a hack, but it should only get called twice in all (once
		# upon connection, once upon signon) so for now it should suffice.
		sleep 0.1;
		$filenos{ fileno($socket) }++;
		$poe_kernel->select( $socket, 'rd_ok', 'wr_ok', 'ex_ok' );
	}
}

1;
__END__

=head1 NAME

POE::Component::OSCAR - A POE Component for the Net::OSCAR module

=head1 SYNOPSIS

use POE qw(Component::OSCAR);
  
[ ... POE set up ... ]

sub _start {
    # start an OSCAR session
    $oscar = POE::Component::OSCAR->new();

    # start an OSCAR session with automatic throttling of new connections
	# to prevent being banned by the server
    $oscar = POE::Component::OSCAR->new( throttle => 4 );

    # set up the "im_in" callback to call your state, "im_in_state"
    $oscar->set_callback( im_in => 'im_in_state');

	# it's good to detect errors if you don't want to get banned
	$oscar->set_callback( error => 'error_state' );
	$oscar->set_callback( admin_error => 'admin_erro_stater' );
	$oscar->set_callback( rate_alert => 'rate_alert_state' );

    # sign on
    $oscar->signon( screenname => $MY_SCREENNAME, password => $MY_PASSWORD );
}

sub im_in_state {
    my ($nothing, $args) = @_[ARG0..$#_];
    my ($object, $who, $what, $away) = @$args;

    print "Got '$what' from $who\n";
}

=head1 DEPENDENCIES

This modules requires C<Net::OSCAR>, C<POE>, and C<Time::HiRes>.

=head1 ABSTRACT

This module is a wrapper around the Net::OSCAR module that allows it to be
used from POE applications.

=head1 DESCRIPTION

The wrapper is very thin, so most of the useful documentation can be found in
the Net::OSCAR module.

Create a new connection with

    $oscar = POE::Component::OSCAR->new();

Though it has an object interface to make coding simpler, this actually spawns
a POE session.  The arguments to the object are passed directly to the 
Net::OSCAR module, with the exception of 'throttle'.  If passed in, the
'throttle' argument will indicate the minimum amount of time the module will
wait between sending messages.  This is useful, since bots that send lots of
messages quickly will get banned.

All other method calls on the object are passed directly to the Net::OSCAR
module.  For instance, to set the debug logging level, use

      $oscar->loglevel( 5 );

The only relevant POE::Component::OSCAR method is 'set_callback' which can
be used to post events to your own session via Net::OSCAR's callbacks.

For instance, to be notified of an incoming message, use

      $oscar->set_callback( im_in => 'im_in_state' );

where 'im_in' is a Net::OSCAR callback (see the Net::OSCAR documentation and
the oscartest script for all the callbacks) and 'im_in_state' is a state
in your POE session.

=head1 SEE ALSO

The examples directory included with this package.

The C<Net::OSCAR> documentation.

The C<oscartest> script, which comes with C<Net::OSCAR>

=head1 AUTHOR

Dan McCormick, E<lt>dan@codeop.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Dan McCormick

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
