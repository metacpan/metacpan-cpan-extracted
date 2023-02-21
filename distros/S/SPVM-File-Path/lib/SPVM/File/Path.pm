package SPVM::File::Path;

our $VERSION = '0.01';

1;

=head1 Name

SPVM::File::Path - Creating and Removing Multi-Level Path

=head1 Description

C<SPVM::File::Path> is the C<File::Path> class in L<SPVM> language. It has methods to create a multi-level path and to remove a directory that contain files or directories within them.

=head1 Usage

  use File::Path;
  
  File::Path->make_path("foo/bar");
  
  File::Path->remove_tree("foo");

=head1 Class Methods

=head2 mkpath

  static method mkpath : int ($path : string, $options = undef : object[]) ;

Creates a multi-level path.

Options:

=over 2

=item C<mode> = C<-1>: L<Int|SPVM::Int>

The mode that is used by L<mkdir|SPVM::Sys::IO/"mkdir"> to create directories.

If the value is less than C<0>, it becomes C<0777>.

=back

=head2 make_path

  static method make_path : int ($path : string, $options = undef : object[]);

The same as L</"mkpath">.

=head2 rmtree

  static method rmtree : int ($path : string);

Removes a directory that contain files or directories within them.

=head2 remove_tree

  static method remove_tree : int ($path : string);

The same as L</"rmtree">.

=head1 See Also

=head2 File::Path

C<SPVM::File::Path> is a Perl's L<File::Path> porting to L<SPVM>.

=head1 Repository

L<SPVM::File::Path - Github|https://github.com/yuki-kimoto/SPVM-File-Path>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright 2023-2023 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

