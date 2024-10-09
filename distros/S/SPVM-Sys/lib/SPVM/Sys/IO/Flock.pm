package SPVM::Sys::IO::Flock;

1;

=head1 Name

SPVM::Sys::IO::Flock - struct flock in the C language

=head1 Description

Sys::IO::Flock class in L<SPVM> is the class for C<struct flock> in the C language.

=head1 Usage

  use Sys::IO::Flock;
  my $flock = Sys::IO::Flock->new;

=head1 Details

This is a pointer class. The pointer of the instance is set to a C<struct flock> object.

=head1 Class Methods

=head2 new

C<native static method new : L<Sys::IO::Flock|SPVM::Sys::IO::Flock> ();>

Create a new C<Sys::IO::Flock> object.

=head1 Instance Methods

=head2 DESTROY

C<native method DESTROY : void ();>

The destructor.

=head2 l_type

C<native method l_type : int ();>

Returns C<l_type>.

=head2 set_l_type

C<native method set_l_type : void ($type : int);>

Sets C<l_type>.

=head2 l_whence

C<native method l_whence : int ();>

Returns C<l_whence>.

=head2 set_l_whence

C<native method set_l_whence : void ($whence : int);>

Sets C<l_whence>.

=head2 l_start

C<native method l_start : long ();>

Returns C<l_start>.

=head2 set_l_start

C<native method set_l_start : void ($start : long);>

Sets C<l_start>.

=head2 l_len

C<native method l_len : long ();>

Returns C<l_len>.

=head2 set_l_len

C<native method set_l_len : void ($len : long);>

Sets C<l_len>.

=head2 l_pid

C<native method l_pid : int ();>

Returns C<l_pid>.

=head2 set_l_pid

C<native method set_l_pid : void ($pid : int);>

Sets C<l_pid>.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

