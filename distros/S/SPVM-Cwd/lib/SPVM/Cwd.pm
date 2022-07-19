package SPVM::Cwd;

our $VERSION = '0.02';

1;

=head1 Name

SPVM::Cwd - get pathname of current working directory

=head1 Usage

  use Cwd;
  my $dir = Cwd->getcwd;
  
  my $abs_path = Cwd->abs_path($file);

=head1 Description

This module provides functions for determining the pathname of the current working directory.

C<Cwd> is a Perl L<Cwd> porting to L<SPVM>.

C<Cwd> is a L<SPVM> module.

=head1 Caution

L<SPVM> is yet experimental status.

=head1 Class Methods

=head2 getcwd

  static method getcwd : string ();

Returns the current working directory. On error returns undef, with L<errno|SPVM::Errno/"errno"> set to indicate the error.

Exposes the POSIX function getcwd(3).

=head2 abs_path

  static method abs_path : string ($file :string)

Uses the same algorithm as getcwd(). Symbolic links and relative-path components ("." and "..") are resolved to return the canonical pathname, just like realpath(3). On error returns undef, with L<Errno->errno|SPVM::Errno/"errno"> set to indicate the error.

=head2 realpath

  static method realpath : string ($file : string)

A synonym for abs_path().

=head1 Repository

L<https://github.com/yuki-kimoto/SPVM-Cwd>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
