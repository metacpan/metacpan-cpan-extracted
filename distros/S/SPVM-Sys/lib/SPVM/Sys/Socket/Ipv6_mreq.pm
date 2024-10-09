package SPVM::Sys::Socket::Ipv6_mreq;

1;

=head1 Name

SPVM::Sys::Socket::Ipv6_mreq - struct ipv6_mreq in the C language

=head1 Description

Sys::Socket::Ipv6_mreq class in L<SPVM> represents L<struct ipv6_mreq|https://linux.die.net/man/7/ipv6> in the C language.

=head1 Usage

  use Sys::Socket::Ipv6_mreq;

=head1 Details

This class is a pointer class. The pointer the instance has is set to a L<struct ipv6_mreq|https://linux.die.net/man/7/ipv6> object.

=head1 Class Methods

=head2 new

C<static method new : L<Sys::Socket::Ipv6_mreq|SPVM::Sys::Socket::Ipv6_mreq> ();>

Create a new L<Sys::Socket::Ipv6_mreq|SPVM::Sys::Socket::Ipv6_mreq> object.

=head1 Instance Methods

=head2 

C<method DESTROY : void ();>

The destructor.

=head2 ipv6mr_multiaddr

C<method ipv6mr_multiaddr : L<Sys::Socket::In6_addr|SPVM::Sys::Socket::In6_addr> ();>

Copies C<ipv6mr_multiaddr> and returns it.

=head2 set_ipv6mr_multiaddr

C<method set_ipv6mr_multiaddr : void ($interface : L<Sys::Socket::In6_addr|SPVM::Sys::Socket::In6_addr>);>

Sets C<ipv6mr_multiaddr>.

=head2 ipv6mr_interface

C<method ipv6mr_interface : int ();>

Returns C<ipv6mr_interface>.

=head2 set_ipv6mr_interface

C<method set_ipv6mr_interface : void ($interface : int);>

Sets C<ipv6mr_interface>.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

