package SPVM::Sys::Socket::Sockaddr::Storage;

1;

=head1 Name

SPVM::Sys::Socket::Sockaddr::Storage - struct sockaddr_storage in C language

=head1 Usage

  use Sys::Socket::Sockaddr::Storage;

=head1 Description

C<Sys::Socket::Sockaddr::Storage> is the class for the C<struct sockaddr_storage> in C<C language>.

This is a L<pointer class|SPVM::Document::Language/"Pointer Class">.

=head1 Inheritance

This class inherits L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

=head1 Class Methods

=head2 new

  static method new : Sys::Socket::Sockaddr::Storage ();

Create a new C<Sys::Socket::Sockaddr::Storage> object.

=head1 Instance Methods

=head2 DESTROY

  method DESTROY : void ();

The destructor.

=head2 sa_family

  method sa_family : int ()

Get C<sa_family>. This is the overriden method of the L<sa_family|SPVM::Sys::Socket::Sockaddr/"sa_family"> method in the Sys::Socket::Sockaddr class.

=head2 ss_family

  method ss_family : int ();

Get C<ss_family>.

=head2 set_ss_family

  method set_ss_family : void ();

Set C<ss_family>.

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

