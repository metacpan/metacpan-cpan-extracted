package SPVM::File::Glob;

our $VERSION = "0.020002";

1;

=head1 Name

SPVM::File::Glob - The BSD glob Porting

=head1 Description

The File::Glob class of L<SPVM> has a method that is a port of the BSD glob function.

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

Copyright (c) 2023 Yuki Kimoto

MIT License
