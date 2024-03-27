package SPVM::Sys::Socket::Sockaddr;

1;

=head1 Name

SPVM::Sys::Socket::Sockaddr - struct sockaddr in the C language

=head1 Description

The Sys::Socket::Sockaddr class in L<SPVM> represents L<struct sockaddr|https://linux.die.net/man/7/ip> in the C language.

=head1 Usage

  use Sys::Socket::Sockaddr;

=head1 Details

This class is a pointer class. The pointer the instance has is set to a L<struct sockaddr|https://linux.die.net/man/7/ip> object.

=head1 Interfaces

=over 2

=item L<Cloneable|SPVM::Cloneable>

=back

=head1 Class Methods

=head2 new

C<static method new : L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr> ();>

Creates a new L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr> object.

=head2 new_with_family

C<static method new_with_family : Sys::Socket::Sockaddr ($family : int);>

Creates a new L<Sys::Socket::Sockaddr::In|SPVM::Sys::Socket::Sockaddr::In> object 
or a new L<Sys::Socket::Sockaddr::In6|SPVM::Sys::Socket::Sockaddr::In6> object 
or a new L<Sys::Socket::Sockaddr::In|SPVM::Sys::Socket::Sockaddr::In> object according to the socket family $family,
and returns it.

Excetpions:

If the address famil is not available, an exception is thrown.

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

The destructor.

=head2 sa_family

C<method sa_family : int ()>

Returns C<sa_family>.

=head2 set_sa_family

C<method sa_family : int ()>

Sets C<sa_family>.

=head2 sizeof

C<method size : int ()>

Returns the size of the structure. This method is planed to be implemented in a child class.

Exception:

Not implemented.
  
=head2 clone

C<method clone : L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr> ();>

Clones this instance. This method is planed to be implemented in a child class.

Exception:

Not implemented.

=head2 upgrade

C<method upgrade : Sys::Socket::Sockaddr ();>

Returns a new L<Sys::Socket::Sockaddr::In|SPVM::Sys::Socket::Sockaddr::In> object,
or a new L<Sys::Socket::Sockaddr::In6|SPVM::Sys::Socket::Sockaddr::In6> object,
or a new L<Sys::Socket::Sockaddr::Un|SPVM::Sys::Socket::Sockaddr::Un> object
according to L</"sa_family">.

Exceptions:

If the address family is not available, an exception is thrown.

=head1 Well Known Child Classes

=over 2

=item L<Sys::Socket::Sockaddr::In|SPVM::Sys::Socket::Sockaddr::In>

=item L<Sys::Socket::Sockaddr::In6|SPVM::Sys::Socket::Sockaddr::In6>

=item L<Sys::Socket::Sockaddr::Un|SPVM::Sys::Socket::Sockaddr::Un>

=item L<Sys::Socket::Sockaddr::Storage|SPVM::Sys::Socket::Sockaddr::Storage>

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

