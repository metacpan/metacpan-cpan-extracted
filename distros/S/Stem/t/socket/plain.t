# t/socket/plain.t

use strict ;

use Stem ;
use Stem::Socket ;

use Test::More tests => 9 ;

my $data = "FOO\n" ;

test_socket() ;

exit 0 ;

sub test_socket {

	my( $self, $accept_event, $connect_event ) ;

	$self = bless {} ;

	$accept_event = Stem::Socket->new(
		'object'	=> $self,
		'port'		=> 10_000,
		'server'	=> 1,
		'method'	=> 'accepted',
	) ;

	die $accept_event unless ref $accept_event ;
	$self->{'accept_event'} = $accept_event ;
	ok( 1, 'listen' ) ;

	$connect_event = Stem::Socket->new(
		'object' => $self,
		'port' => 10_000,
	) ;

	die $connect_event unless ref $connect_event ;
	$self->{'connect_event'} = $connect_event ;
	ok( 1, 'connect' ) ;

	Stem::Event::start_loop() ;

	ok( 1, 'event loop exit' ) ;
}

sub accepted {

	my( $self, $accepted_sock ) = @_ ;

	ok( 1, 'accepted' ) ;

	$self->{'accepted_sock'} = $accepted_sock ;

	$self->{'accept_event'}->shut_down() ;

	ok( 1, 'accept canceled' ) ;

	my $read_event = Stem::Event::Read->new(
		'object'	=>	$self,
		'fh'		=>	$accepted_sock,
	) ;

	$self->{'read_event'} = $read_event ;
}

sub readable {

	my( $self ) = @_ ;

	ok(1, 'read event triggered' ) ;

	my $bytes_read = sysread( $self->{'accepted_sock'},
				  my $read_buf, 1000 ) ;

	ok( $bytes_read, 'read byte count' ) ;

	is( $read_buf, $data, 'read event compare' ) ;

	close( $self->{'accepted_sock'} ) ;

	$self->{'read_event'}->cancel() ;
}

sub connected {

	my( $self, $connected_sock ) = @_ ;

	ok( 1, 'connected' ) ;

	my $wcnt = $connected_sock->syswrite( $data ) ;
#print "SYSWR C $wcnt\n" ;

	$self->{'connect_event'}->shut_down() ;
}
