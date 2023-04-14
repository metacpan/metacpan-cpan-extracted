package SPVM::Sys::Socket::Ip_mreq_source;

1;

=head1 Name

SPVM::Sys::Socket::Ip_mreq_source - struct ip_mreq_source in C language

=head1 Usage

  use Sys::Socket::Ip_mreq_source;

=head1 Description

C<Sys::Socket::In_addr> is the class for the C<struct ip_mreq_source> in C<C language>.

This is a L<pointer class|SPVM::Document::Language/"Pointer Class">.

=head1 Class Methods

=head2 new

  static method new : Sys::Socket::Ip_mreq_source ();

Create a new C<Sys::Socket::Ip_mreq_source> object.

=head1 Instance Methods

=head2 DESTROY

  method DESTROY : void ();

The destructor.

=head2 imr_multiaddr

  method imr_multiaddr : Sys::Socket::In_addr ();

Get C<imr_multiaddr>. This is a L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr> object.

=head2 set_imr_multiaddr

  method set_imr_multiaddr : void ($address : Sys::Socket::In_addr);

Set C<imr_multiaddr>. This is a L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr> object.

=head2 imr_interface

  method imr_interface : Sys::Socket::In_addr ();

Get C<imr_interface>. This is a L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr> object.

=head2 set_imr_interface

  method set_imr_interface : void ($address : Sys::Socket::In_addr);

Set C<imr_interface>. This is a L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr> object.

=head2 imr_sourceaddr

  method imr_sourceaddr : Sys::Socket::In_addr ();

Get C<imr_sourceaddr>. This is a L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr> object.

=head2 set_imr_sourceaddr

  method set_imr_sourceaddr : void ($address : Sys::Socket::In_addr);

Set C<imr_sourceaddr>. This is a L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr> object.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

