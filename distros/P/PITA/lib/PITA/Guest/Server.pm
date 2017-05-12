package PITA::Guest::Server;

use 5.008;
use strict;
use Params::Util               1.00 ();
use POE::Wheel::Run           1.299 ();
use POE::Declare::HTTP::Server 0.05 ();
use PITA::Guest::Server::HTTP       ();

our $VERSION = '0.60';

use POE::Declare 0.58 {
	Hostname      => 'Param',
	Port          => 'Param',
	Program       => 'Param',
	Uploads       => 'Param',
	Mirrors       => 'Param',
	StartupEvent  => 'Message',
	ShutdownEvent => 'Message',
	pinged        => 'Attribute',
	uploaded      => 'Attribute',
	mirrored      => 'Attribute',
	status        => 'Internal',
	http          => 'Internal',
	child         => 'Internal',
};

use constant {
	STOPPED  => 1,
	STARTING => 1,
	RUNNING  => 1,
	STOPPING => 1,
};





######################################################################
# Constructor and Accessors

sub new {
	my $self = shift->SUPER::new(@_);

	# Set up tracking variables
	$self->{status}   = STOPPED;
	$self->{pinged}   = 0;
	$self->{mirrored} = [ ];
	$self->{uploaded} = [ ];

	# Check params
	unless ( Params::Util::_ARRAY($self->Program) ) {
		die "Missing or invalid 'Program' param";
	}

	# Create the web server
	$self->{http} = PITA::Guest::Server::HTTP->new(
		Hostname      => $self->Hostname,
		Port          => $self->Port,
		Mirrors       => $self->Mirrors,
		StartupEvent  => $self->lookback('http_startup_event'),
		StartupError  => $self->lookback('http_startup_error'),
		ShutdownEvent => $self->lookback('http_shutdown_event'),
		PingEvent     => $self->lookback('http_ping'),
		MirrorEvent   => $self->lookback('http_mirror'),
		UploadEvent   => $self->lookback('http_upload'),
	);

	return $self;
}










######################################################################
# Main Methods

# Sort of half-assed Process compatibility for testing purposes
sub run {
	$_[0]->start;
	POE::Kernel->run;
	return 1;
}

sub start {
	my $self = shift;
	unless ( $self->spawned ) {
		$self->spawn;
		$self->post('startup');
	}
	return 1;
}

sub stop {
	my $self = shift;
	if ( $self->spawned ) {
		$self->post('shutdown');
	}
	return 1;
}





######################################################################
# Event Methods

sub startup : Event {
	# Kick off the blanket startup timeout
	$_[SELF]->{status} = STARTING;
	$_[SELF]->startup_timeout_start;
	$_[SELF]->post('http_startup');
}

sub http_startup : Event {
	$_[SELF]->{http}->start;
}

sub http_startup_event : Event {
	$_[SELF]->post('child_startup');
}

sub http_startup_error : Event {
	die "Failed to start the web server";
}

sub http_shutdown_event : Event {
	# Nothing to do?
}

sub http_ping : Event {
	$_[SELF]->startup_timeout_stop;
	$_[SELF]->activity_timeout_start;
	$_[SELF]->{status} = RUNNING;
	$_[SELF]->{pinged} = 1;
	$_[SELF]->StartupEvent;
}

sub http_mirror : Event {
	$_[SELF]->activity_timeout_start;
	push @{$_[SELF]->{mirrored}}, [ $_[ARG1], $_[ARG2], $_[ARG3] ];
}

sub http_upload : Event {
	$_[SELF]->activity_timeout_start;
	push @{$_[SELF]->{uploaded}}, [ $_[ARG1], $_[ARG2] ];

	# Do we have everything?
	unless ( grep { not defined $_ } values %{$_[SELF]} ) {
		$_[SELF]->{status} = STOPPING;
		$_[SELF]->activity_timeout_stop;
		$_[SELF]->shutdown_timeout_start;
	}
}

sub child_startup : Event {
	# Spawn the program
	$_[SELF]->{child} = POE::Wheel::Run->new(
		Program     => $_[SELF]->Program,
		StdoutEvent => 'child_stdout',
		StderrEvent => 'child_stderr',
		CloseEvent  => 'child_close',
	);

	# Trap signals from the child as well.
	# NOTE: This needs to be brought under the management of POE::Declare.
	$_[KERNEL]->sig_child( $_[SELF]->{child}->PID => 'child_signal' );
}

sub child_stdout : Event {
	# Do nothing for now
	# print STDERR "# CHILD STDOUT $_[ARG0]\n";
}

sub child_stderr : Event {
	# Do nothing for now
	# print STDERR "# CHILD STDERR $_[ARG0]\n";
}

sub child_close : Event {
	# print STDERR "# CHILD CLOSE\n";
	if ( $_[SELF]->{child} ) {
		# Wait for a little to give the child time to SIGCHILD us
		$_[SELF]->child_signal_timeout_start;
	}
}

sub child_signal : Event {
	# print STDERR "# CHILD SIGCHILD $_[ARG2]\n";
	$_[SELF]->child_signal_timeout_stop;
	if ( $_[SELF]->{child} ) {
		$_[SELF]->post('shutdown');
	}
}

sub child_signal_timeout : Timeout(5) {
	if ( $_[SELF]->{child} ) {
		$_[SELF]->post('shutdown');
	}
}

sub startup_timeout : Timeout(30) {
	$_[SELF]->post('shutdown');
}

sub activity_timeout : Timeout(3600) {
	$_[SELF]->post('shutdown');
}

sub shutdown_timeout : Timeout(60) {
	$_[SELF]->post('shutdown');
}

sub shutdown : Event {
	$_[SELF]->finish;
	$_[SELF]->ShutdownEvent(
		$_[SELF]->pinged,
		$_[SELF]->mirrored,
		$_[SELF]->uploaded,
	);
	$_[SELF]->{status} = STOPPED;
}





######################################################################
# Support Methods

sub finish {
	my $self = shift;

	# Clean up our children
	if ( $self->{child} ) {
		$self->{child}->kill(9);
		$self->{child} = undef;
	}
	if ( $self->{http}->spawned ) {
		$self->{http}->call('shutdown');
	}

	# Call parent method to clean out other things
	$self->SUPER::finish(@_);
}

compile;
