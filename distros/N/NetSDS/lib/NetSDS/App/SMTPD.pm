package NetSDS::App::SMTPD;

use 5.8.0;
use strict;
use warnings;

package NetSDS::App::SMTPD::Socket;

use IO::Socket;
use base 'NetSDS::App';

use version; our $VERSION = '1.301';

sub new {
	my ( $proto, %args ) = @_;

	my $class = ref $proto || $proto;
	my $self = ( %args ? $class->SUPER::new(%args) : bless {}, $class );
	
	return $self->create_socket( $args{'port'} );
}

sub create_socket {
	my $self   = shift;
	my $socket = IO::Socket->new;

	$socket->socket( PF_INET, SOCK_STREAM, scalar getprotobyname('tcp') );
	$socket->blocking(0);
	$self->{'_socket'} = $socket;
	return $self;
}

sub get_socket_handle { +shift->{'_socket'} }
sub close             { +shift->get_socket_handle->close }

package NetSDS::App::SMTPD::Client;

use Net::Server::Mail::SMTP;
use base 'NetSDS::App::SMTPD::Socket';

sub set_smtp {
	my $self = shift;
	$self->{'ip'} = shift;

	$self->{'_smtp'} = Net::Server::Mail::SMTP->new( socket => $self->get_socket_handle );
	return $self;
}

sub set_callback { +shift->get_smtp->set_callback(@_) }
sub process      { +shift->get_smtp->process(@_) }
sub get_smtp     { +shift->{'_smtp'} }
sub get_header   { $_[0]->{'headers'}{ lc $_[1] } }
sub get_msg      { +shift->{'msg'} }
sub get_ip       { +shift->{'ip'} }

sub get_mail {
	my ( $self, $data ) = @_;
	my @lines = split /\r\n(?! )/, $$data;

	$self->{'headers'} = {};
	my $i;

	for ( $i = 0 ; $lines[$i] ; $i++ ) {
		my ( $key, $value ) = split /:\s*/, $lines[$i], 2;

		$key = lc $key;

		if ( exists $self->{'headers'}{$key} ) {
			unless ( ref $self->{'headers'}{$key} ) {
				my $temp = $self->{'headers'}{$key};
				$self->{'headers'}{$key} = [ $temp, $value ];
			} else {
				push @{ $self->{'headers'}{$key} }, $value;
			}
		} else {
			$self->{'headers'}{$key} = $value;    #TODO fix me could be several Received
		}
	}

	$self->{'msg'} = join "\r\n", @lines[ $i + 1 .. $#lines ];
	return 1;
} ## end sub get_mail

package NetSDS::App::SMTPD;

use base 'NetSDS::App::SMTPD::Socket';
use IO::Socket;

sub create_socket {
	my ( $self, $port ) = @_;
	$port ||= 2525;
	return unless $port;

	$self->SUPER::create_socket;

	setsockopt( $self->get_socket_handle, SOL_SOCKET, SO_REUSEADDR, 1 );
	bind( $self->get_socket_handle, sockaddr_in( $port, INADDR_ANY ) ) or die "Can't use port $port";
	listen( $self->get_socket_handle, SOMAXCONN ) or die "Can't listen on port: $port";

	return $self;
}

sub can_read {
	my $self = shift;
	my $rin  = '';

	vec( $rin, fileno( $self->get_socket_handle ), 1 ) = 1;
	return select( $rin, undef, undef, undef );
}

sub accept {
	my $self = shift;
	$self->can_read;

	my $client = NetSDS::App::SMTPD::Client->new;
	my $peer   = accept( $client->get_socket_handle, $self->get_socket_handle );

	if ($peer) {
		$client->set_smtp( inet_ntoa( ( sockaddr_in($peer) )[1] ) );
		$self->speak( "connection from ip [" . $client->get_ip . "]" );
		$client->set_callback( DATA => \&data, $client );

		return $client;
	}
}

sub data {
	my ( $smtp, $data ) = @_;
	return $smtp->{'_context'}->get_mail($data);
}

sub process {
	my $self   = shift;
	my $client = $self->accept;

	return unless $client;
	$client->process;

	$client->close;
	$self->speak( "connection from ip [" . $client->get_ip . "] closed" );

	return $client;
}

1;

__END__

=head1 NAME

NetSDS::App::SMTPD

=head1 SYNOPSIS

use NetSDS::App::SMTPD

=head1 Packages

=head1 NetSDS::App::SMTPD::Socket

Needs for work with socket. This module is a parent for  NetSDS::App::SMTPD and NetSDS::App::SMTPD::Client and
a child of a NetSDS::APP

=head3 ITEMS

=over 8

=item B<create_socket>

Creating a simple socket which could be transformed into a listening in NetSDS::App::SMTPD and
could be used in NetSDS::App::SMTPD::Client for accept connection

=item B<can_read>

This method uses for making a timeout before connections to the server:
if there is no connections to accept, program would be just waiting in select while the connection appeared.

=item B<close_socket>

Close socket

=back

=head1 NetSDS::App::SMTPD::Client

Provides the smtp protocol bu using Net::Server::Mail::SMTP.
Had attributes: smtp - an object of Net::Server::Mail::SMTP, ip - 
ip of the remote host, headers - ref hash with headers of a message, 
msg - a body of a message.

=head3 ITEMS

=over 8

=item B<set_callback> and B<process>

All that subs do - its only call the methods of a Net::Server::Mail::SMTP with the same name.

=item B<get_mail>

In this sub we parse message and set headers of the object and message body. This sub is call as a 
callback on event DATA

=item B<get_header> and B<get_msg>

Get methods that make you access to a header of a msg and message body.
Example: $client->get_header('FROM') or $client->get_header('to');

=back

=head1 NetSDS::App::SMTPD

This module init a smtp-server.

=head3 ITEMS

=over 8

=item B<create_socket>

Init a listening socket by creating a simple socket Super::create_socket and make it listening.

=item B<data>

Takes - a message that has been received, parses them and prepare 
the structure of headers, body for next actions

=item B<accept>

Waiting for an smtp connection and that accept it.

=item B<data>

=item B<process>

=back

=head1 Example

	#!/usr/bin/env perl

	use strict;
	use warnings;

	Receiver->run(
		infinite  => 1,
		debug     => 1,
		verbose   => 1,
		conf_file => '../conf/mts-receiver.conf',
	);

	1;

	package Receiver;
	use base 'NetSDS::App::SMTPD';
				    
	sub process {
		my $self = shift;
		my $client = $self->SUPER::process;

		#do something with msg;
		my $from = $client->get_header('from');
		my $msg = $client->get_msg;

		.....

		return $self;
	};

or you could reinit process like this:

	sub process {
		my $self = shift;
		my $client = $self->accept;

		return unless $client;
		$client->process;
	
		#do something
		......
		$client->close;
		return $self;
	};

=head1 AUTHOR

Yana Kornienko <yana@netstyle.com.ua>

=cut
