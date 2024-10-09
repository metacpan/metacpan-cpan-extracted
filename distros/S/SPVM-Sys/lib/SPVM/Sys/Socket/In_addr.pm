package SPVM::Sys::Socket::In_addr;

1;

=head1 Name

SPVM::Sys::Socket::In_addr - struct in_addr in the C language

=head1 Description

Sys::Socket::In_addr class in L<SPVM> represents L<struct in_addr|https://linux.die.net/man/3/inet_network> in the C language.

=head1 Usage

  use Sys::Socket::In_addr;

=head1 Details

This class is a pointer class. The pointer the instance has is set to a L<struct in_addr|https://linux.die.net/man/3/inet_network> object.

=head1 Super Class

L<Sys::Socket::In_addr_base|SPVM::Sys::Socket::In_addr_base>

=head1 Class Methods

=head2 new

C<static method new : L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr> ();>

Creates a new L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr> object.

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

The destructor.

=head2 s_addr

C<method s_addr : int ();>

Returns C<s_addr>.

=head2 set_s_addr

C<method set_s_addr : void ($s_addr : int)>

Sets C<s_addr>.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

