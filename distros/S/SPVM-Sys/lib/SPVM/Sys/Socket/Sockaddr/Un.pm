package SPVM::Sys::Socket::Sockaddr::Un;

1;

=head1 Name

SPVM::Sys::Socket::Sockaddr::Un - struct sockaddr_un in the C language

=head1 Description

Sys::Socket::Sockaddr::Un class in L<SPVM> represents L<struct sockaddr_un|https://linux.die.net/man/7/unix> in the C language.

=head1 Usage

  use Sys::Socket::Sockaddr::Un;

=head1 Details

This class is a pointer class. The pointer the instance has is set to a L<struct sockaddr_un|https://linux.die.net/man/7/unix> object.

=head1 Super Class

L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>

=head1 Class Methods

=head2 new

C<static method new : L<Sys::Socket::Sockaddr::Un|SPVM::Sys::Socket::Sockaddr::Un> ();>

Creates a new L<Sys::Socket::Sockaddr::Un|SPVM::Sys::Socket::Sockaddr::Un> object.

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

The destructor.

=head2 sa_family

C<method sa_family : int ()>

Returns C<sa_family>.

=head2 sun_family

C<method sun_family : int ();>

Returns C<sun_family>.

=head2 set_sun_family

C<method set_sun_family : void ($family : int)>

Sets C<sun_family>.

=head2 sun_path

C<method sun_path : string ();>

Copies C<sun_path> and returns it.

=head2 set_sun_path

C<method set_sun_path : void ($path : string)>

Sets C<sun_path>.

=head2 size

C<method size : int ()>

Returns the size of C<struct sockaddr_un>.

=head2 clone

C<method clone : L<Sys::Socket::Sockaddr::Un|SPVM::Sys::Socket::Sockaddr::Un> ();>

Clones this instance and returns it.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

