package SPVM::Sys::Select::Constant;

1;

=head1 Name

SPVM::Sys::Select::Constant - Constant values for Select.

=head1 Usage

  use Sys::Select::Constant as Select;
  
  my $o_trunc = Select->O_TRUNC;

=head1 Description

C<Sys::Select::Constant> is the class for the constant values for the select function.

=head1 Class Methods

=head2 FD_SETSIZE

  static method FD_SETSIZE : int ();

Get the constant value of C<FD_SETSIZE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
