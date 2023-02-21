package SPVM::File::Glob;

our $VERSION = '0.01';

1;

=head1 Name

SPVM::File::Glob - The glob Function

=head1 Description

C<SPVM::File::Glob> is the C<File::Glob> class in L<SPVM> language. This class has the glob method.

=head1 Usage

  use File::Glob;
  
  my $files = File::Glob->glob("path/*");
  
  my $files = File::Glob->glob("path/?oo");

=head1 Class Methods

  static method glob : string[] ($pattern : string);

The L<bsd_glob|https://metacpan.org/pod/File::Glob#bsd_glob> porting.

The C<~> expansion is not supported.

=head1 Repository

L<SPVM::File::Glob - Github|https://github.com/yuki-kimoto/SPVM-File-Glob>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright 2023-2023 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

