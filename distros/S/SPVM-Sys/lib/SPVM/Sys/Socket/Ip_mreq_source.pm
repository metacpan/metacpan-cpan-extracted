package SPVM::Sys::Socket::Ip_mreq_source;

1;

=head1 Name

SPVM::Sys::Socket::Ip_mreq_source - struct ip_mreq_source in the C language

=head1 Description

Sys::Socket::In_addr class in L<SPVM> represents L<struct ip_mreq_source|https://linux.die.net/man/7/ip> in the C language.

=head1 Usage

  use Sys::Socket::Ip_mreq_source;

=head1 Details

This class is a pointer class. The pointer the instance has is set to a L<struct ip_mreq_source|https://linux.die.net/man/7/ip> object.

=head1 Class Methods

=head2 new

C<static method new : L<Sys::Socket::Ip_mreq_source|SPVM::Sys::Socket::Ip_mreq_source> ();>

Create a new L<Sys::Socket::Ip_mreq_source|SPVM::Sys::Socket::Ip_mreq_source> object.

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

The destructor.

=head2 imr_multiaddr

C<method imr_multiaddr : L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr> ();>

Copies C<imr_multiaddr> and returns it.

=head2 set_imr_multiaddr

C<method set_imr_multiaddr : void ($address : L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr>);>

Sets C<imr_multiaddr>.

=head2 imr_interface

C<method imr_interface : L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr> ();>

Copies C<imr_interface> and returns it.

=head2 set_imr_interface

C<method set_imr_interface : void ($address : L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr>);>

Sets C<imr_interface>.

=head2 imr_sourceaddr

C<method imr_sourceaddr : L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr> ();>

Copies C<imr_sourceaddr> and returns it.

=head2 set_imr_sourceaddr

C<method set_imr_sourceaddr : void ($address : L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr>);>

Sets C<imr_sourceaddr>.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

