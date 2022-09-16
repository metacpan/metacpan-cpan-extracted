package SPVM::Sys::Socket::Ipv6_mreq;

1;

=head1 Name

SPVM::Sys::Socket::Ipv6_mreq - struct ipv6_mreq in C language

=head1 Usage

  use Sys::Socket::Ipv6_mreq;

=head1 Description

C<Sys::Socket::Ipv6_mreq> is the class for the C<struct ipv6_mreq> in C<C language>.

This is a L<pointer class|SPVM::Document::Language/"Pointer Class">.

=head1 Class Methods

=head2 new

  static method new : Sys::Socket::Ipv6_mreq ();

Create a new C<Sys::Socket::Ipv6_mreq> object.

=head1 Instance Methods

=head2 

  method DESTROY : void ();

=head2 ipv6mr_multiaddr

  method ipv6mr_multiaddr : Sys::Socket::In6_addr ();

Get C<ipv6mr_multiaddr>. This is a L<Sys::Socket::In6_addr|SPVM::Sys::Socket::In6_addr> object.

=head2 set_ipv6mr_multiaddr

  method set_ipv6mr_multiaddr : void ($interface : Sys::Socket::In6_addr);

Set C<ipv6mr_multiaddr>. This is a L<Sys::Socket::In6_addr|SPVM::Sys::Socket::In6_addr> object.

=head2 ipv6mr_interface

  method ipv6mr_interface : int ();

Get C<ipv6mr_interface>.

=head2 set_ipv6mr_interface

  method set_ipv6mr_interface : void ($interface : int);

Set C<ipv6mr_interface>.

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

