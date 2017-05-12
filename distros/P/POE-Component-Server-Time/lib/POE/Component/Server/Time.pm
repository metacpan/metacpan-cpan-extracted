# $Id: Time.pm,v 1.1.1.1 2005/01/27 15:36:15 chris Exp $
#
# POE::Component::Server::Time, by Chris 'BinGOs' Williams <chris@bingosnet.co.uk>
#
# This module may be used, modified, and distributed under the same
# terms as Perl itself. Please see the license that came with your Perl
# distribution for details.
#

package POE::Component::Server::Time;
$POE::Component::Server::Time::VERSION = '1.16';
#ABSTRACT: A POE component that implements an RFC 868 Time server.

use strict;
use warnings;
use Carp;
use POE;
use Socket;
use base qw(POE::Component::Server::Echo);

use constant DATAGRAM_MAXLEN => 1024;
use constant DEFAULT_PORT => 37;

sub spawn {
  my $package = shift;
  croak "$package requires an even number of parameters" if @_ & 1;

  my %parms = @_;

  $parms{'Alias'} = 'Time-Server' unless defined $parms{'Alias'} and $parms{'Alias'};
  $parms{'tcp'} = 1 unless defined $parms{'tcp'} and $parms{'tcp'} == 0;
  $parms{'udp'} = 1 unless defined $parms{'udp'} and $parms{'udp'} == 0;

  my $self = bless { }, $package;

  $self->{CONFIG} = \%parms;

  POE::Session->create(
        object_states => [
                $self => { _start => '_server_start',
                           _stop  => '_server_stop',
                           shutdown => '_server_close' },
                $self => [ qw(_accept_new_client _accept_failed _client_input _client_error _client_flushed _get_datagram) ],
                          ],
        ( ref $parms{'options'} eq 'HASH' ? ( options => $parms{'options'} ) : () ),
  );

  return $self;
}

sub _accept_new_client {
  my ($kernel,$self,$socket,$peeraddr,$peerport,$wheel_id) = @_[KERNEL,OBJECT,ARG0 .. ARG3];
  $peeraddr = inet_ntoa($peeraddr);

  my $wheel = POE::Wheel::ReadWrite->new (
        Handle => $socket,
        Filter => POE::Filter::Line->new(),
        InputEvent => '_client_input',
        ErrorEvent => '_client_error',
	FlushedEvent => '_client_flushed',
  );

  $self->{Clients}->{ $wheel->ID() } = { Wheel => $wheel, peeraddr => $peeraddr, peerport => $peerport };;
  $wheel->put( time );
  undef;
}

sub _client_input {
  undef;
}

sub _client_flushed {
  my ($kernel,$self,$wheel_id) = @_[KERNEL,OBJECT,ARG0];
  delete $self->{Clients}->{ $wheel_id }->{Wheel};
  delete $self->{Clients}->{ $wheel_id };
  undef;
}

sub _get_datagram {
  my ( $kernel, $self, $socket ) = @_[ KERNEL, OBJECT, ARG0 ];

  my $remote_address = recv( $socket, my $message = "", DATAGRAM_MAXLEN, 0 );
    return unless defined $remote_address;

  my $output = time();
  send( $socket, $output, 0, $remote_address ) == length( $output )
      or warn "Trouble sending response: $!";
  undef;
}

qq[Mind is perpetual motion. Its symbol is the sphere.];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Server::Time - A POE component that implements an RFC 868 Time server.

=head1 VERSION

version 1.16

=head1 SYNOPSIS

 use POE::Component::Server::Time;

 my $self = POE::Component::Server::Time->spawn( 
	Alias => 'Time-Server',
	BindAddress => '127.0.0.1',
	BindPort => 7777,
	options => { trace => 1 },
 );

=head1 DESCRIPTION

POE::Component::Server::Time implements a RFC 868 L<http://www.faqs.org/rfcs/rfc868.html> TCP/UDP Time server, using
L<POE>. It is a class inherited from L<POE::Component::Server::Echo>.

=head1 METHODS

=over

=item C<spawn>

Takes a number of optional values:

  "Alias", the kernel alias that this component is to be blessed with; 
  "BindAddress", the address on the local host to bind to, defaults to 
                 POE::Wheel::SocketFactory> default; 
  "BindPort", the local port that we wish to listen on for requests, 
              defaults to 37 as per RFC, this will require "root" privs on UN*X; 
  "options", should be a hashref, containing the options for the component's session, 
             see POE::Session for more details on what this should contain.

=back

=head1 BUGS

Report any bugs through L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<POE>

L<POE::Session>

L<POE::Wheel::SocketFactory>

L<POE::Component::Server::Echo>

L<http://www.faqs.org/rfcs/rfc868.html>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
