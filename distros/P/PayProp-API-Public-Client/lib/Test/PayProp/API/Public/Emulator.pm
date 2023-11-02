package Test::PayProp::API::Public::Emulator;

use strict;
use warnings;

use Mouse;
use Parallel::ForkManager;
use Time::HiRes qw/ gettimeofday tv_interval usleep /;
use IO::Socket::INET;
use POSIX qw( :sys_wait_h );

has [ qw/exec scheme host/ ] => (
	is       => 'rw',
	isa      => 'Value',
	required => 1,
);

has [ qw/argv/ ] => (
	is       => 'rw',
	isa      => 'Str',
	required => 0,
	default  => sub { '' },
);

has [ qw/argv_second/ ] => (
	is       => 'rw',
	isa      => 'Str',
	required => 0,
	default  => sub { '' },
);

has [ qw/pid/ ] => (
	is       => 'rw',
	isa      => 'Int',
);

has [ qw/port/ ] => (
	is       => 'rw',
	isa      => 'Int',
	default  => sub {
		# avoid clashing with any other test running an emulator at the same time
		my $port = 6450 + $$ % 100;
		$ENV{EMULATOR_PORT} = $port;
		return $port;
	},
);

has 'path' => (
	is      => 'rw',
	isa     => 'Str',
	default => sub { 't/emulation/' },
);

has 'pm' => (
	is      => 'rw',
	isa     => 'Parallel::ForkManager',
	lazy    => 1,
	default => sub {
		return Parallel::ForkManager->new( 2 );
	},
);

sub url {
	my ( $self ) = @_;
	return $self->scheme . "://" . $self->host . ":" . $self->port;
}

sub start {
	my ( $self ) = @_;

	if (my $pid = $self->pm->start) {
		$self->pid( $pid );
	}
	else {
		my @command = (
			$^X,
			$self->path . $self->exec,
			"daemon",
			"-l",
			$self->scheme . "://*:" . $self->port,
			$self->argv,
			( $self->argv_second ? ( $self->argv_second ) : () ),
		);

		main::note( "EMULATOR: " . join( " ",@command ) );
		exec( @command );
	}

	# give emulator time to start up:
	my $timeout = 10;
	my @t = gettimeofday;
	while () {
		die "Process @{[ $self->pid ]} terminated"
			if waitpid $self->pid, WNOHANG;

		# Sleep up-front because a previous server may still be closing down
		usleep 500_000;

		if (tv_interval(\@t) > $timeout) {
			$self->stop;
			die "Emulator didn't come up within $timeout seconds";
		}

		my $sock = IO::Socket::INET->new(
			Proto    => 'tcp',
			PeerHost => '127.0.0.1',
			PeerPort => $self->port,
		);
		last if $sock && $sock->connected;
	}

	return $self->pid;
}

sub stop {
	my ( $self ) = @_;
    $self->pm->finish if $self->pm;

	if ( $self->pid ) {
		kill( 'HUP',$self->pid );
	}
}

sub DEMOLISH {

	my ( $self ) = @_;
	$self->stop;
}

__PACKAGE__->meta->make_immutable;
