package Printer::EVOLIS::Parallel;

use warnings;
use strict;

use POSIX;
use Data::Dump qw(dump);

our $debug = 0;

=head1 NAME

Printer::EVOLIS::Parallel - chat with parallel port printer

=head1 METHODS

=head2 new

  my $p = Printer::EVOLIS::Parallel->new( '/dev/usb/lp0' );

=cut

sub new {
	my ( $class, $port ) = @_;
	my $self = { port => $port };
	bless $self, $class;
	return $self;
}

=head2 command

  my $response = $p->command( 'Rsn' );

=cut

sub command {
	my ( $self, $send ) = @_;
	$send = "\e$send\r" unless $send =~ m/^\e/;
	$self->send( $send );
}

sub send {
	my ( $self, $send ) = @_;

	my $port = $self->{port};
	die "no port $port" unless -e $port;

	my $parallel;

	# XXX we need to reopen parallel port for each command
	sysopen( $parallel, $port, O_RDWR | O_EXCL) || die "$port: $!";

	foreach my $byte ( split(//,$send) ) {
		warn "#>> ",dump($byte),$/ if $debug;
		syswrite $parallel, $byte, 1;
	}

	close($parallel);
	# XXX and between send and receive
	sysopen( $parallel, $port, O_RDWR | O_EXCL) || die "$port: $!";

	my $response;
	while ( ! sysread $parallel, $response, 1 ) { sleep 0.1 }; # XXX wait for 1st char
	my $byte;
	while( sysread $parallel, $byte, 1 ) {
		warn "#<< ",dump($byte),$/ if $debug;
		last if $byte eq "\x00";
		$response .= $byte;
	}
	close($parallel);

	return $response;
}

1;
