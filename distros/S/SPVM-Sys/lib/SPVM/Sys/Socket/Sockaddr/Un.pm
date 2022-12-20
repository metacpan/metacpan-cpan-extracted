package SPVM::Sys::Socket::Sockaddr::Un;

1;

=head1 Name

SPVM::Sys::Socket::Sockaddr::Un - struct sockaddr_un in C language

=head1 Usage

  use Sys::Socket::Sockaddr::Un;

=head1 Description

C<Sys::Socket::Sockaddr::Un> is the class for the C<struct sockaddr_un> in C<C language>.

This is a L<pointer class|SPVM::Document::Language/"Pointer Class">.

=head1 Inheritance

This class inherits L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

=head1 Class Methods

=head2 new

  static method new : Sys::Socket::Sockaddr::Un ();

=head1 Instance Methods

=head2 DESTROY

  method DESTROY : void ();

The destructor.

=head2 sa_family

  method sa_family : int ()

Gets C<sa_family>. This is the overriden method of the L<sa_family|SPVM::Sys::Socket::Sockaddr/"sa_family"> method in the Sys::Socket::Sockaddr class.

=head2 sun_family

  method sun_family : int ();

Gets C<sun_family>.

=head2 set_sun_family

  method set_sun_family : void ($family : int)

Sets C<sun_family>.

=head2 copy_sun_path

  method copy_sun_path : string ();

Copies C<sun_path>.

=head2 set_sun_path

  method set_sun_path : void ($path : string)

Sets C<sun_path>.

=head2 sizeof

  method sizeof : int ()

The size of C<struct sockaddr_un>.

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

