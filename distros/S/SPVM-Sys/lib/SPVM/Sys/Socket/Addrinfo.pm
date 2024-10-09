package SPVM::Sys::Socket::Addrinfo;

1;

=head1 Name

SPVM::Sys::Socket::Addrinfo - struct addrinfo in the C language

=head1 Description

Sys::Socket::Addrinfo class in L<SPVM> represents L<struct addrinfo|https://linux.die.net/man/3/getaddrinfo> in the C language.

=head1 Usage

  use Sys::Socket::Addrinfo;

=head1 Details

This class is a pointer class. The pointer the instance has is set to a L<struct addrinfo|https://linux.die.net/man/3/getaddrinfo> object.

=head1 Class Methods

=head2 new

C<method new : L<Sys::Socket::Addrinfo|SPVM::Sys::Socket::Addrinfo> ();>

Create a new L<Sys::Socket::Addrinfo|SPVM::Sys::Socket::Addrinfo> object.

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

The destructor.

=head2 ai_flags

C<method ai_flags : int ();>

Returns C<ai_flags>.

=head2 set_ai_flags

C<method set_ai_flags : void ($ai_flags : int);>

Sets C<ai_flags>.

=head2 ai_family

C<method ai_family : int ();>

Returns C<ai_family>.

=head2 set_ai_family

C<method set_ai_family : void ($ai_family : int);>

Sets C<ai_family>.

=head2 ai_socktype

C<method ai_socktype : int ();>

Returns C<ai_socktype>.

=head2 set_ai_socktype

C<method set_ai_socktype : void ($ai_socktype : int);>

Sets C<ai_socktype>.

=head2 ai_protocol

C<method ai_protocol : int ();>

Returns C<ai_protocol>.

=head2 set_ai_protocol

C<method set_ai_protocol : void ($ai_protocol : int);>

Sets C<ai_protocol>.

=head2 ai_addr

C<method ai_addr : L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr> ();>

Copies C<ai_addr> and returns it.

=head2 ai_canonname

C<method ai_canonname : string ();>

Copies C<ai_canonname> and returns it.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

