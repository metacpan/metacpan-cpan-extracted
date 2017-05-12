# $Id: Chargen.pm,v 1.3 2005/01/27 13:48:24 chris Exp $
#
# POE::Component::Server::Echo, by Chris 'BinGOs' Williams <chris@bingosnet.co.uk>
#
# This module may be used, modified, and distributed under the same
# terms as Perl itself. Please see the license that came with your Perl
# distribution for details.
#

package POE::Component::Server::Chargen;
$POE::Component::Server::Chargen::VERSION = '1.16';
#ABSTRACT: A POE component that implements an RFC 864 Chargen server.

use strict;
use warnings;
use Carp;
use POE;
use Socket;
use base qw(POE::Component::Server::Echo);

use constant DATAGRAM_MAXLEN => 1024;
use constant DEFAULT_PORT => 19;

sub spawn {
  my $package = shift;
  croak "$package requires an even number of parameters" if @_ & 1;

  my %parms = @_;

  $parms{'Alias'} = 'Chargen-Server' unless defined $parms{'Alias'} and $parms{'Alias'};
  $parms{'tcp'} = 1 unless defined $parms{'tcp'} and $parms{'tcp'} == 0;
  $parms{'udp'} = 1 unless defined $parms{'udp'} and $parms{'udp'} == 0;

  my $self = bless { }, $package;

  $self->{CONFIG} = \%parms;
  $self->{start_ascii} = 32;

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

  $self->{Clients}->{ $wheel->ID() } = { Wheel => $wheel, peeraddr => $peeraddr, peerport => $peerport, start_ascii => $self->{start_ascii} };
  $wheel->put( _generate_line(\$self->{Clients}->{ $wheel->ID() }->{start_ascii}) );
  undef;
}

sub _client_input {
  undef;
}

sub _client_flushed {
  my ($kernel,$self,$wheel_id) = @_[KERNEL,OBJECT,ARG0];

  if ( defined $self->{Clients}->{ $wheel_id } and defined $self->{Clients}->{ $wheel_id }->{Wheel} ) {
	$self->{Clients}->{ $wheel_id }->{Wheel}->put( _generate_line(\$self->{Clients}->{ $wheel_id }->{start_ascii}) );
  }
  undef;
}

sub _get_datagram {
  my ( $kernel, $self, $socket ) = @_[ KERNEL, OBJECT, ARG0 ];

  my $remote_address = recv( $socket, my $message = "", DATAGRAM_MAXLEN, 0 );
    return unless defined $remote_address;

  my $start_ascii = $self->{start_ascii};

  my $reply = _generate_line( \$start_ascii );

  send( $socket, $reply, 0, $remote_address ) == length($reply)
      or warn "Trouble sending response: $!";

  undef;
}

sub _generate_line {
  my $start_ascii = shift;
  my $chargen_line = join(
    '',
    map { chr }
    ($$start_ascii ..  $$start_ascii + 71)
  );
  $chargen_line =~ tr[\x7F-\xDD][\x20-\x7E];
  $$start_ascii = 32 if ++$$start_ascii > 126;
  return $chargen_line;
}

qq[A Gen of chars];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Server::Chargen - A POE component that implements an RFC 864 Chargen server.

=head1 VERSION

version 1.16

=head1 SYNOPSIS

 use POE::Component::Server::Chargen;

 my $self = POE::Component::Server::Chargen->spawn( 
	Alias => 'Chargen-Server',
	BindAddress => '127.0.0.1',
	BindPort => 7777,
	options => { trace => 1 },
 );

=head1 DESCRIPTION

POE::Component::Server::Chargen implements a RFC 864 L<http://www.faqs.org/rfcs/rfc864.html> TCP/UDP chargen server, using
L<POE>. It is a class inherited from L<POE::Component::Server::Echo|POE::Component::Server::Echo>.

=head1 METHODS

=over

=item C<spawn>

Takes a number of optional values:

  "Alias", the kernel alias that this component is to be blessed with; 
  "BindAddress", the address on the local host to bind to, defaults to 
                 POE::Wheel::SocketFactory> default; 
  "BindPort", the local port that we wish to listen on for requests, defaults 
              to 19 as per RFC, this will require "root" privs on UN*X; 
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

L<http://www.faqs.org/rfcs/rfc862.html>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
