package Net::LibLO;

################
#
# liblo: perl bindings
#
# Copyright 2005 Nicholas J. Humfrey <njh@aelius.com>
#

use XSLoader;
use Carp;

use Net::LibLO::Address;
use Net::LibLO::Message;
use Net::LibLO::Bundle;
use strict;

use vars qw/$VERSION/;

$VERSION="0.06";

XSLoader::load('Net::LibLO', $VERSION);



sub new {
    my $class = shift;
    my ($port, $protocol) = @_;
    
    # Default to using random UDP port
    $port = '' if (!defined $port);
    $protocol = 'udp' if (!defined $protocol);

    # Bless the hash into an object
    my $self = { 'method_handlers'=>[] };
    bless $self, $class;
        
    # Create new server instance
    $self->{server} = Net::LibLO::lo_server_new_with_proto( $port, $protocol );
    if (!defined $self->{server}) {
    	carp("Error creating lo_server");
    	undef $self;
    }

   	return $self;
}

sub get_port {
    my $self=shift;
	return Net::LibLO::lo_server_get_port( $self->{server} );
}

sub get_url {
    my $self=shift;
	return Net::LibLO::lo_server_get_url( $self->{server} );
}

sub send {
	my $self=shift;
	my $dest=shift;
	
	# Contruct an address object ?
	if (ref($dest) ne 'Net::LibLO::Address') {
		$dest = new Net::LibLO::Address($dest);
	}
	
	if (ref($_[0]) eq 'Net::LibLO::Bundle') {
		# Send a bundle
		my $bundle = shift;
		return Net::LibLO::lo_send_bundle_from( $dest->{'address'}, $self->{'server'}, $bundle->{'bundle'} );
	} else {
		# Send a meesage
		my $path = shift;
		my $mesg;
		if (ref($_[0]) eq 'Net::LibLO::Message') {
			$mesg = $_[0];
		} else {
			$mesg = new Net::LibLO::Message( @_ );
		}
		
		return Net::LibLO::lo_send_message_from( $dest->{'address'}, $self->{'server'}, $path, $mesg->{'message'} );
	}
}

sub recv {
	my $self=shift;

	return Net::LibLO::lo_server_recv( $self->{'server'} );
}

sub recv_noblock {
	my $self=shift;
	my ($timeout) = @_;

	$timeout = 0 unless (defined $timeout);

	return Net::LibLO::lo_server_recv_noblock( $self->{'server'}, $timeout );
}

sub add_method {
    my $self=shift;
    my ($path, $typespec, $handler, $userdata) = @_;
    
    # Check parameters
    carp "Missing typespec parameter" unless (defined $typespec);
    carp "Missing path parameter" unless (defined $path);
    carp "Missing handler parameter" unless (defined $handler);
    carp "Handler parameter isn't a code reference" unless (ref($handler) eq 'CODE');
    #carp "Handle parameter isn't subroutine reference" unless (ref
    
    # Create hashref to store info in
    my $handle_ref = {
    	'method' => $handler,
    	'server' => $self,
    	'path' => $path,
    	'typespec' => $typespec,
    	'userdata' => $userdata
    };
    
    # Add the method handler
	my $result = Net::LibLO::lo_server_add_method( $self->{server}, $path, $typespec, $handle_ref );
	if (!defined $result) {
    	carp("Error adding method handler");
	} else {
		# Add it to array of method handlers
		push( @{$self->{'method_handlers'}}, $handle_ref );
	}
	
	return $result;
}

#sub del_method {
#    my $self=shift;
#    my ($path, $typespec) = @_;
#
#	my $result = Net::LibLO::lo_server_del_method( $self->{server}, $path, $typespec );
#
#	# XXX: Remove from array too
#}

sub _method_dispatcher {
	my ($ref, $mesg, $path, $typespec, @params) = @_;
	
	my $serv = $ref->{server};
	my $message = new Net::LibLO::Message( $mesg );
	my $userdata = $ref->{userdata};

	# Call the proper perl subroutine
	return &{$ref->{method}}( $serv, $message, $path, $typespec, $userdata, @params);
}


sub DESTROY {
    my $self=shift;
    
    if (defined $self->{server}) {
    	Net::LibLO::lo_server_free( $self->{server} );
    	undef $self->{server};
    }
}


1;

__END__

=pod

=head1 NAME

Net::LibLO - Perl interface for liblo Lightweight OSC library

=head1 SYNOPSIS

  use Net::LibLO;

  my $lo = new Net::LibLO( );
  $lo->add_method( "/reply", 's', \&my_handler );
  $lo->send( 'osc://localhost:5600/', '/foo/bar', 's', 'Hello World' );

=head1 DESCRIPTION

Net::LibLO class is used to send and recieve OSC messages using LibLO
(the Lightweight OSC library). The coding style is slightly different to 
the C interface to LibLO, because it makes use of perl's Object Oriented 
functionality. 


=over 4

=item B<new( [port], [protocol] )>

Create a new LibLO object for sending a recieving messages.
If the C<port> is missing, then a random port number is chosen.
If the C<protocol> is missing, than UDP is used.

=item B<send( dest, bundle )>

Send a bundle to the sepecified destination.

C<dest> can either be a Net::LibLO::Address object, a URL or a port.

C<bundle> should be a Net::LibLO::Bundle object.

=item B<send( dest, path, message )>

Send a message to the sepecified destination.

C<dest> can either be a Net::LibLO::Address object, a URL or a port.

C<message> should be a Net::LibLO::Message object.

=item B<send( dest, path, typespec, params... )>

Construct and send a message to the sepecified destination.

C<dest> can either be a Net::LibLO::Address object, a URL or a port.

C<path> is the path to send the message to.

C<typespec> and C<params> are passed through to create the new message.

=item B<recv()>

Block and wait to receive a single message. Returns the length of the 
message in bytes  or number less than 1 on failure. Length of message 
is returned, whether the message has been handled by a method or not.

=item B<recv_noblock( [timeout] )>

Look for an OSC message waiting to be received.
Waits for C<timeout> milliseconds for a message and then returns the 
length of the message, or 0 if there was no message.
Use a value of 0 to return immediatly.

=item B<add_method( path, typespec, handler, userdata )>

Add an OSC method to the specifed server.

C<path> is the OSC path to register the method to.
If C<undef> is passed the method will match all paths.

C<typespec> is OSC typespec that the method accepts. Incoming messages with
similar typespecs (e.g. ones with numerical types in the same position) will
be coerced to the typespec given here.

C<handler> is a reference to the method handler callback subroutine that will 
be called if a matching message is received. 

C<user_data> is a value that will be passed to the callback subroutine,
when its invoked matching from this method.

=item B<my_handler( serv, mesg, path, typespec, userdata, @params )>

This is order of parameters that will be passed to your method handler
subroutines. 

C<serv> is the Net::LibLO object that the method is registered with.

C<mesg> is a Net::LibLO::Message object for the incoming message.

C<path> is the path the incoming message was sent to.

C<typespec> If you specided types in your method creation call then this
will match those and the incoming types will have been coerced to match,
otherwise it will be the types of the arguments of the incoming message.

C<userdata> This contains the userdata value passed in the call to C<add_method> 

C<params> is an array of values associated with the message

=item B<get_port()>

Returns the port the socket is bound to.

=item B<get_url()>

Returns the full URL for talking to this server.

=back



=head1 SEE ALSO

L<Net::LibLO::Address>

L<Net::LibLO::Bundle>

L<Net::LibLO::Message>

L<http://liblo.sourceforge.net/>

=head1 AUTHOR

Nicholas J. Humfrey <njh@aelius.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Nicholas J. Humfrey

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut
