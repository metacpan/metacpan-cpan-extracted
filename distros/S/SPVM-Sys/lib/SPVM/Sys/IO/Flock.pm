package SPVM::Sys::IO::Flock;

1;

=head1 Name

SPVM::Sys::IO::Flock - struct flock in C language

=head1 Usage

  use Sys::IO::Flock;
  my $flock = Sys::IO::Flock->new;

=head1 Description

C<Sys::IO::Flock> is the class for C<struct flock> in C<C language>.

This is a L<pointer class|SPVM::Document::Language/"Pointer Class">.

=head1 Class Methods

=head2 new

  native static method new : Sys::IO::Flock ();

Create a new C<Sys::IO::Flock> object.

=head1 Instance Methods

=head2 DESTROY

  native method DESTROY : void ();

The destructor.

=head2 l_type

  native method l_type : short ();

Get C<l_type>.

=head2 set_l_type

  native method set_l_type : void ($type : short);

Set C<l_type>.

=head2 l_whence

  native method l_whence : short ();

Get C<l_whence>.

=head2 set_l_whence

  native method set_l_whence : void ($whence : short);

Set C<l_whence>.

=head2 l_start

  native method l_start : long ();

Get C<l_start>.

=head2 set_l_start

  native method set_l_start : void ($start : long);

Set C<l_start>.

=head2 l_len

  native method l_len : long ();

Get C<l_len>.

=head2 set_l_len

  native method set_l_len : void ($len : long);

Set C<l_len>.

=head2 l_pid

  native method l_pid : int ();

Get C<l_pid>.

=head2 set_l_pid

  native method set_l_pid : void ($pid : int);

Set C<l_pid>.

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
