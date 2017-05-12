# t/socket/SockFork.pm
# common code for forked socket tests

package SockFork ;

use strict ;


use Stem ;
use Stem::Socket ;

use Test::More tests => 7 ;

my $self = bless {} ;
my $pid ;
my $port = 9000 ;
my $data = "FOO\n" ;

sub test {

	my ( $ssl_client_args, $ssl_server_args ) = @_ ;

	my ( @ssl_client_args, @ssl_server_args ) ;

	if ( @{$ssl_client_args} ) {

		@ssl_client_args = ( 'ssl_args' => $ssl_client_args ) ;
		@ssl_server_args = ( 'ssl_args' => $ssl_server_args ) ;
	}


	if ( $pid = fork() ) {

		sleep 1 ;

		$self->{'pid'} = $pid ;

		ok( 1, 'parent' ) ;

#print "SSL @ssl_client_args\n" ;

		my $connect_sock = Stem::Socket->new(
				'object'	=> $self,
				'port'		=> $port,
				@ssl_client_args,
				
		) ;

		die $connect_sock unless ref $connect_sock ;

		ok( 1, 'created connect event' ) ;
		$self->{'connect_sock'} = $connect_sock ;
	}
	else {

		my $listen_sock = Stem::Socket->new(
				'object'	=> $self,
				'port'		=> $port,
				'server'	=> 1,
				'method'	=> 'accepted',
				@ssl_server_args
		) ;

		die $listen_sock unless ref $listen_sock ;
		$self->{'listen_sock'} = $listen_sock ;
	}

	Stem::Event::start_loop() ;

	ok( 1, 'event loop exit' ) ;
}

sub connected {

	my( $self, $client_sock ) = @_ ;

#print "CLIENT [$client_sock]\n" ;

	ok( 1, 'connected' ) ;

	$self->{'client_sock'} = $client_sock ;

	my $wcnt = $client_sock->syswrite( $data ) ;

#print "WCNT [$wcnt] $!\n" ;

	my $client_read_event = Stem::Event::Read->new(
		'object'	=> $self,
		'fh'		=> $client_sock,
		'method'	=> 'client_readable',
	) ;

	ok( $client_read_event, 'created client read event' ) ;

	$self->{'client_read_event'} = $client_read_event ;
}

sub client_readable {

	my( $self ) = @_ ;

	ok( 1, 'client readable' ) ;

	my $buf ;

	my $client_sock = $self->{'client_sock'} ;

	my $cnt = $client_sock->sysread( $buf, 100 ) ;

	is( $buf, "[$data]", 'client read data' ) ;
	
#print "CLIENT READ $cnt [$buf]\n" ;

	$self->{'connect_sock'}->shut_down() ;
	$self->{'client_read_event'}->cancel() ;
}

sub accepted {

	my( $self, $accepted_sock ) = @_ ;

	$self->{'accepted_sock'} = $accepted_sock ;

	$self->{'listen_sock'}->shut_down() ;

	my $server_read_event = Stem::Event::Read->new(
		'object'	=> $self,
		'fh'		=> $accepted_sock,
		'method'	=> 'server_readable',
	) ;

	$self->{'server_read_event'} = $server_read_event ;
}

sub server_readable {

	my( $self ) = @_ ;

	my $accepted_sock = $self->{'accepted_sock'} ;

	my $cnt = $accepted_sock->sysread( my $buf, 100 ) ;

	$accepted_sock->syswrite( "[$buf]" ) ;

# exit forked child

	exit ;
}

1 ;
