#+##############################################################################
#                                                                              #
# File: Net/STOMP/Client/Peer.pm                                               #
#                                                                              #
# Description: Peer support for Net::STOMP::Client                             #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Net::STOMP::Client::Peer;
use strict;
use warnings;
our $VERSION  = "2.5";
our $REVISION = sprintf("%d.%02d", q$Revision: 2.2 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use Params::Validate qw(validate :types);

#
# constants
#

use constant I_PROTO => 0;
use constant I_HOST  => 1;
use constant I_PORT  => 2;
use constant I_ADDR  => 3;

#+++############################################################################
#                                                                              #
# constructor                                                                  #
#                                                                              #
#---############################################################################

my %new_options = (
    "proto" => {
        type     => SCALAR,
        regex    => qr/^(tcp|ssl|stomp|stomp\+ssl)$/,
    },
    "host" => {
        type     => SCALAR,
        regex    => qr/^[a-z0-9\.\-\:]+$/,
    },
    "port" => {
        type     => SCALAR,
        regex    => qr/^\d+$/,
    },
    "addr" => {
        optional => 1,
        type     => SCALAR,
        regex    => qr/^\d+\.\d+\.\d+\.\d+$/,
    },
);

sub new : method {
    my($class, %option, $object);

    $class = shift(@_);
    %option = validate(@_, \%new_options);
    $object = [ @option{ qw(proto host port addr) } ];
    return(bless($object, $class));
}

#+++############################################################################
#                                                                              #
# getters                                                                      #
#                                                                              #
#---############################################################################

sub proto : method {
    my($self) = @_;

    return($self->[I_PROTO]);
}

sub host : method {
    my($self) = @_;

    return($self->[I_HOST]);
}

sub port : method {
    my($self) = @_;

    return($self->[I_PORT]);
}

sub addr : method {
    my($self) = @_;

    return($self->[I_ADDR]);
}

sub uri : method {
    my($self) = @_;

    return(sprintf("%s://%s:%s", @{ $self }[I_PROTO, I_HOST, I_PORT]));
}

1;

__END__

=head1 NAME

Net::STOMP::Client::Peer - Peer support for Net::STOMP::Client

=head1 SYNOPSIS

  use Net::STOMP::Client;
  $stomp = Net::STOMP::Client->new(host => "127.0.0.1", port => 61613);
  ...
  $peer = $stomp->peer();
  if ($peer) {
      # we are indeed connected to a STOMP server
      printf("server uri is %s\n", $peer->uri());
  }

=head1 DESCRIPTION

This module is used internally by L<Net::STOMP::Client> before connection
and also afterwards to expose information about the STOMP server that the
client is connected to.

=head1 METHODS

This module provides the following methods:

=over

=item new([OPTIONS])

return a new Net::STOMP::Client::Peer object (class method)

=item proto([STRING])

get the protocol

=item host([STRING])

get the host name or address

=item port([STRING])

get the port number

=item addr([STRING])

get the host numerical IP address

=item uri()

get the host URI in the form C<PROTO://HOST:PORT>

=back

=head1 SEE ALSO

L<Net::STOMP::Client>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2010-2021
