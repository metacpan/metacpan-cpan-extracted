package SPVM::Sys::Socket::Sockaddr::Storage;

1;

=head1 Name

SPVM::Sys::Socket::Sockaddr::Storage - struct sockaddr_storage in the C language

=head1 Description

Sys::Socket::Sockaddr::Storage class in L<SPVM> represents L<struct sockaddr_storage|https://linux.die.net/man/7/socket> in the C language.

=head1 Usage

  use Sys::Socket::Sockaddr::Storage;

=head1 Details

This class is a pointer class. The pointer the instance has is set to a L<struct sockaddr_storage|https://linux.die.net/man/7/socket> object.

=head1 Super Class

L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>

=head1 Class Methods

=head2 new

C<static method new : L<Sys::Socket::Sockaddr::Storage|SPVM::Sys::Socket::Sockaddr::Storage> ();>

Create a new L<Sys::Socket::Sockaddr::Storage|SPVM::Sys::Socket::Sockaddr::Storage> object.

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ()>

The destructor.

=head2 sa_family

C<method sa_family : int ()>

Returns C<sa_family>.

=head2 ss_family

C<method ss_family : int ()>

Returns C<ss_family>.

=head2 set_ss_family

C<method set_ss_family : void ($family : int)>

Sets C<ss_family>.

=head2 size

C<method size : int ()>

Returns the size of C<struct sockaddr_storage>.

=head2 clone

C<method clone : L<Sys::Socket::Sockaddr::Storage|SPVM::Sys::Socket::Sockaddr::Storage> ();>

Clones this instance and returns it.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

