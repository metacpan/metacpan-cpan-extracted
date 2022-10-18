package SPVM::Sys::Ioctl::Constant;

1;

=head1 Name

SPVM::Sys::Ioctl::Constant - Constant values for ioctl.

=head1 Usage

  use Sys::Ioctl::Constant as Ioctl;
  
=head1 Description

C<Sys::Ioctl::Constant> is the class for the constant values for the C<ioctl> function in C<C language>.

=head1 Class Methods

=head2 FIONBIO

  static method FIONBIO : int ();

Get the constant value of C<FIONBIO>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

