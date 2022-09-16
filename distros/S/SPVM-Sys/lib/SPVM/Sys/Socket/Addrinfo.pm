package SPVM::Sys::Socket::Addrinfo;

1;

=head1 Name

SPVM::Sys::Socket::Addrinfo - struct addrinfo in C language

=head1 Usage

  use Sys::Socket::Addrinfo;

=head1 Description

C<Sys::Socket::Addrinfo> is the class for the C<struct addrinfo> in C<C language>.

This is a L<pointer class|SPVM::Document::Language/"Pointer Class">.

=head1 Class Methods

=head2 new

  method new : Sys::Socket::Addrinfo ();

Create a new Sys::Socket::Addrinfo object.

=head1 Instance Methods

=head2 DESTROY

  method DESTROY : void ();

The destructor.

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
