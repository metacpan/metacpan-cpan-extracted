package SPVM::Sys::Socket::In_addr;

1;

=head1 Name

SPVM::Sys::Socket::In_addr - struct in_addr in C language

=head1 Usage

  use Sys::Socket::In_addr;

=head1 Description

C<Sys::Socket::In_addr> is the class for the C<struct in_addr> in C<C language>.

This is a L<pointer class|SPVM::Document::Language/"Pointer Class">.

=head1 Class Methods

=head2 new

  static method new : Sys::Socket::In_addr ();

Creates a new C<Sys::Socket::In_addr> object.

=head1 Instance Methods

=head2 DESTROY

  method DESTROY : void ();

The destructor.

=head2 s_addr

  method s_addr : int ();

Gets C<s_addr>.

=head2 set_s_addr

  method set_s_addr : void ();

Sets C<s_addr>.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

