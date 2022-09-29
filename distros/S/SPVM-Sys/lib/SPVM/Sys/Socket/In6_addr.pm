package SPVM::Sys::Socket::In6_addr;

1;

=head1 Name

SPVM::Sys::Socket::In6_addr - struct in6_addr in C language

=head1 Usage

  use Sys::Socket::In6_addr;

=head1 Description

C<Sys::Socket::In6_addr> is the class for the C<struct in6_addr> in C<C language>.

This is a L<pointer class|SPVM::Document::Language/"Pointer Class">.

=head1 Class Methods

=head2 new

  static method new : Sys::Socket::In6_addr ();

=head1 Instance Methods

=head2 DESTROY

  method DESTROY : void ();

=head2 s6_addr

  method s6_addr : string ();

Gets C<s6_addr>. Its value is copied and a new string is created.

=head2 set_s6_addr

  method set_s6_addr : void ($address : string);

Sets C<s6_addr>.

The address must be defined. Otherwise an exception will be thrown.

The length of the address must be less than or equal to 16. Otherwise an exception will be thrown.

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

