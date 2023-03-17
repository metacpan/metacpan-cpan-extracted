package SPVM::File::Basename::Instance;

1;

=head1 Name

SPVM::File::Basename::Instance - Parsing File Path into Directory and Base Name.

=head1 Description

C<SPVM::File::Basename::Instance> is the C<File::Basename::Instance> class in L<SPVM> language.

This class parses a file path into a directory and a base name.

=head1 Usage

  use File::Basename::Instance;
  
  my $fb = File::Basename::Instance->new;
  
  my $path = "dir/a.txt";
  
  # fileparse
  {
    my $ret = $fb->fileparse($path);
    
    # a.txt
    my $base_name = $ret->[0];
    
    # dir/
    my $dir_name = $ret->[1];
  }
  
  # basename
  {
    # a.txt
    my $base_name = $fb->basename($path);
  }

  # dirname
  {
    # dir
    my $dir_name = $fb->dirname($path);
  }

=head1 Class Methods

=head2 new

  static method new : File::Basename::Instance ();

=head1 Instance Methods

=head2 fileparse

  method fileparse : string[] ($path : string);

=head2 basename

  method basename : string ($path : string);

=head2 dirname

  method dirname : string ($path : string);

=head1 Well Known Child Classes

=over 2

=item L<File::Basename::Instance::Unix|SPVM::File::Basename::Instance::Unix>

=item L<File::Basename::Instance::Win32|SPVM::File::Basename::Instance::Win32>

=back

=head1 Repository

L<SPVM::File::Basename::Instance - Github|https://github.com/yuki-kimoto/SPVM-File-Basename>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright 2023-2023 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

