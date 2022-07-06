package SPVM::Cwd;

our $VERSION = '0.01';

1;

=head1 Name

SPVM::Cwd - get pathname of current working directory

=head1 Synopsys

  use Cwd;
  my $dir = Cwd->getcwd;

=head1 Description

This module provides functions for determining the pathname of the current working directory.

C<Cwd> is a L<SPVM> module.

=head1 Caution

L<SPVM> is yet experimental status.

=head1 Class Methods

=head2 getcwd

  static method getcwd : string ();

Returns the current working directory. On error returns undef, with L<errno|SPVM::Errno/"errno"> set to indicate the error.

Exposes the POSIX function getcwd(3).

=head1 Repository

L<https://github.com/yuki-kimoto/SPVM-Cwd>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
