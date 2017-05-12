package Net::Radius::Server;

use 5.008;
use strict;
use warnings;
use base qw/Class::Accessor/;

our $VERSION = do { sprintf "%0.3f", 1+(q$Revision: 107 $ =~ /\d+/g)[0] / 1000 };

42;

__END__

=head1 NAME

Net::Radius::Server - Framework for RADIUS Servers

=head1 SYNOPSIS

  use Net::Radius::Server;

=head1 DESCRIPTION

C<Net::Radius::Server> provides an extensible framework to create
RADIUS servers suitable for non-standard scenarios where
authentication needs to consider multiple factors. The RADIUS
responses may be created by arbitrarily complex rules that process the
request packet as well as any external data accessible to Perl.

RADIUS request processing can as well include custom -- and sometimes
complex -- processes. For instance, you could want to record a copy of
every RADIUS request received by the server for audit purposes.

The following modules or module hierarchies are included in this
distribution as well:

=over

=item C<Net::Radius::Server::NS>

This class uses C<Net::Server(3)> to construct a complete RADIUS server.

=item C<Net::Radius::Server::Base>

A general base class that contains exported constants and methods for
the framework.

=item C<Net::Radius::Server::DBStore>

Provide access to an underlying Berkeley DB Database for storing
attributes received in the RADIUS requests or in any tuple provided at
transaction processing time.

=item C<Net::Radius::Server::Match>

The base model for match methods. Match methods are used to decide
whether a given rule can be applied. Match methods usually operate on
the RADIUS request as well as the peer data and other environmental
factors.

=item C<Net::Radius::Server::Match::Simple>

This is a simplistic match-method factory that can test for a variety
of conditions (peer address and port, RADIUS request type, presence
and contents of specific attribues).

=item C<Net::Radius::Server::Set>

The base model for set methods. Set methods are expected to craft a
response packet and instruct the RADIUS server how/when/if respond to
the given request.

=item C<Net::Radius::Server::Set::Simple>

An example of set-method factory class. It allows for setting specific
RADIUS attributes, both standard and vendor-specific and setting
packet codes.

=back

As you might have guessed by now, implementation of new features is
done through subclassing and overriding of selected functions. This
provides for an isolated yet well integrated environment.

=head2 The invocation hashref

C<Net::Radius::Server::Match> C<-E<gt>match()> methods,
C<Net::Radius::Server::Set> C<-E<gt>set()> methods and the secret,
dictionary and rule subs described in C<Net::Radius::Server::NS> are
invoked passing a single hash reference as argument. This hash
reference is shared through all the calls, providing an effective
means to have those objects share some space on a per-request basis.

The hashref contains the following entries:

=over

=item B<packet>

The RADIUS packet data received with no conversions.

=item B<peer_addr>

The address of the peer that sent the RADIUS packet.

=item B<peer_host>

If available, the reverse of B<peer_addr>.

=item B<peer_port>

The socket port used by our peer to send the RADIUS packet.

=item B<port>

The local socket port through which the RADIUS packet was received.

=item B<server>

Only available under C<Net::Radius::Server::NS>, this is the
C<Net::Server> object used to service requests.

=item B<secret>

Only available after calling the method returned by the
C<nrs_secret_script> under C<Net::Radius::Server::NS>. This is the
RADIUS shared secret used to encode and decode valid requests.

=item B<dict>

Only available after calling the method returned by the
C<nrs_dictionary_script> under C<Net::Radius::Server::NS>. This is the
RADIUS dictionary used to encode and decode valid requests.

=item B<request>

After succesful decoding, that requires both a correct secret and a
dictionary, this entry contains the RADIUS request in a
C<Net::Radius::Packet> object.

=item B<response>

After succesful decoding, that requires both a correct secret and a
dictionary, this entry contains an empty RADIUS packet as a
C<Net::Radius::Packet> object. C<-E<gt>set()> methods are expected to
modify this packet to craft a suitable response.

=back

=head2 Using Linux-PAM and LDAP

The accompanying modules can use LDAP and Linux-PAM to authenticate
users or otherwise, make more complex choices. An example used by the
author, uses an LDAP attribute to decide if the username must be
authenticated through RADIUS proxying or against an LDAP server.

Other uses are possible, such as adding specific RADIUS attributes to
the responses based on LDAP attributes.

=head2 EXPORT

None by default.


=head1 HISTORY

  $Log$
  Revision 1.4  2007/01/02 23:27:11  lem
  Added missing prerequisites. Also documented what can be done with
  LDAP and Linux-PAM

  Revision 1.3  2006/12/14 15:52:25  lem
  Fix CVS tags


=head1 SEE ALSO

Perl(1), Net::Radius::Packet(3), Net::Radius::Server::NS(3), Net::Server(3).

=head1 AUTHOR

Luis E. Muñoz, E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Luis E. Muñoz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.8.6 itself.

=cut
