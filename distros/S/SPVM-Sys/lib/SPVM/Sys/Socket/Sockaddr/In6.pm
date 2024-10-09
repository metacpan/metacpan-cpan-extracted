package SPVM::Sys::Socket::Sockaddr::In6;

1;

=head1 Name

SPVM::Sys::Socket::Sockaddr::In6 - struct sockaddr_in6 in the C language

=head1 Usage

  use Sys::Socket::Sockaddr::In6;

=head1 Description

Sys::Socket::Sockaddr::In6 class in L<SPVM> represents L<struct sockaddr_in6|https://linux.die.net/man/7/ipv6> in the C language.

=head1 Details

This class is a pointer class. The pointer the instance has is set to a L<struct sockaddr_in6|https://linux.die.net/man/7/ipv6> object.

=head1 Super Class

L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>

=head1 Class Methods

=head2 new

C<static method new : L<Sys::Socket::Sockaddr::In6|SPVM::Sys::Socket::Sockaddr::In6> ();>

Create a new L<Sys::Socket::Sockaddr::In6|SPVM::Sys::Socket::Sockaddr::In6> object.

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ()>

The destructor.

=head2 sa_family

C<method sa_family : int ()>

Returns C<sa_family>.

=head2 sin6_family

C<method sin6_family : int ();>

Returns C<sin6_family>.

=head2 set_sin6_family

C<method set_sin6_family : void ($family : int)>

Sets C<sin6_family>.

=head2 sin6_flowinfo

C<method sin6_flowinfo : int ()>

Returns C<sin6_flowinfo>.

=head2 set_sin6_flowinfo

C<method set_sin6_flowinfo : void ($flowinfo : int)>

Sets C<sin6_flowinfo>.

=head2 sin6_scope_id

C<method sin6_scope_id : int ();>

Returns C<sin6_scope_id>.

=head2 set_sin6_scope_id

C<method set_sin6_scope_id : void ($scope_id : int)>

Sets C<sin6_scope_id>.

=head2 sin6_addr

C<method sin6_addr : L<Sys::Socket::In6_addr|SPVM::Sys::Socket::In6_addr> ();>

Copies C<sin6_addr> and returns it.

=head2 set_sin6_addr

C<method set_sin6_addr : void ($address : L<Sys::Socket::In6_addr|SPVM::Sys::Socket::In6_addr>);>

Sets C<sin6_addr>.

Exceptions:

The address must be defined. Otherwise an exception is thrown.

=head2 sin6_port

C<method sin6_port : int ();>

Returns C<sin6_port>.

=head2 set_sin6_port

C<method set_sin6_port : void ($port : int);>

Sets C<sin6_port>.

=head2 size

C<method size : int ()>

Returns the size of C<struct sockaddr_in6>.

=head2 clone

C<method clone : L<Sys::Socket::Sockaddr::In6|SPVM::Sys::Socket::Sockaddr::In6> ();>

Clones this instance and returns it.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

