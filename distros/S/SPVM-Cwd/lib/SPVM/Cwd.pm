package SPVM::Cwd;

our $VERSION = '0.05';

1;

=head1 Name

SPVM::Cwd - Getting Pathname of Current Working Directory

=head1 Usage

  use Cwd;
  
  my $dir = Cwd->getcwd;
  
  my $abs_path = Cwd->abs_path($file);

=head1 Description

C<SPVM::Cwd> provides methods for determining the pathname of the current working directory.

This module is the Perl's L<Cwd> porting to L<SPVM>.

=head1 Class Methods

=head2 getcwd

  static method getcwd : string ();

Calls the L<getcwd|SPVM::Sys::IO/"getcwd"> method in the L<Sys::IO|SPVM::Sys::IO> class and returns the return value.

On Windows, the path separaters C<\> of the return value are replaced with C</>.

=head2 abs_path

  static method abs_path : string ($file :string)

The alias for the L</"realpath"> method.

=head2 realpath

  static method realpath : string ($file : string)

Calls the L<realpath|SPVM::Sys::IO/"realpath"> method in the L<Sys::IO|SPVM::Sys::IO> class except for Windows and returns the return value.

On Windows, Calls the L<_fullpath|SPVM::Sys::IO/"_fullpath"> method in the L<Sys::IO|SPVM::Sys::IO> class and returns the return value.

On Windows, the path separaters C<\> of the return value are replaced with C</>.

=head2 getdcwd

  static method getdcwd : string ($drive = undef : string) {

The C<$drive> is a drive letter such as C<C:>, C<D:>. It is converted to the drive id.

And calls the L<_getdcwd|SPVM::Sys::IO/"_getdcwd"> method in the L<Sys::IO|SPVM::Sys::IO> returns the return value.

On Windows, the path separaters C<\> of the return value are replaced with C</>

Exceptions:

The getdcwd is not supported on this system(_WIN32).

The length of the $drive must be 2.

The first character of the $drive must be [a-zA-Z].

The second character of the $drive must be ":".

=head1 Repository

L<https://github.com/yuki-kimoto/SPVM-Cwd>

=head1 See Also

=head2 SPVM::Sys

L<SPVM::Sys> provides system calls for changing working directory. C<SPVM::Cwd> calls the methods in the L<SPVM::Sys> class.

=head2 Cwd

C<SPVM::Cwd> is the Perl's L<Cwd> porting to L<SPVM>.

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright 2022-2023 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
