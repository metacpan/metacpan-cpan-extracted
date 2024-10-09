package SPVM::Sys::Socket::In6_addr;

1;

=head1 Name

SPVM::Sys::Socket::In6_addr - struct in6_addr in the C language

=head1 Description

Sys::Socket::In6_addr class in L<SPVM> represents L<struct in6_addr|https://linux.die.net/man/7/ipv6> in the C language.

=head1 Usage

  use Sys::Socket::In6_addr;

=head1 Details

This class is a pointer class. The pointer the instance has is set to a L<struct in6_addr|https://linux.die.net/man/7/ipv6> object.

=head1 Class Methods

=head2 new

C<static method new : L<Sys::Socket::In6_addr|SPVM::Sys::Socket::In6_addr> ();>

Creates a new L<Sys::Socket::In6_addr|SPVM::Sys::Socket::In6_addr> object.

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

The destructor.

=head2 s6_addr

C<method s6_addr : string ();>

Copies C<s6_addr> and returns it.

=head2 set_s6_addr

C<method set_s6_addr : void ($address : string);>

Sets C<s6_addr>.

Exceptions.

The address must be defined. Otherwise an exception is thrown.

The length of the address must be less than or equal to 16. Otherwise an exception is thrown.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

