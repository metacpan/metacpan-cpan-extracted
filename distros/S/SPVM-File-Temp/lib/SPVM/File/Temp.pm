package SPVM::File::Temp;

our $VERSION = "0.022";

1;

=head1 Name

SPVM::File::Temp - Creating Temporary Files and Directories

=head1 Description

The File::Temp class in L<SPVM> has methods to create temporary files and directories.

=head1 Usage

  use File::Temp;
  
  my $tmp_dir = File::Temp->newdir;
  
  my $tmp_dir_name = $tmp_dir->dirname;

=head1 Class Methods

=head2 newdir

C<static method newdir : L<File::Temp::Dir|SPVM::File::Temp::Dir> ();>

Creates a temporary directory and returns a new L<File::Temp::Dir|SPVM::File::Temp::Dir> object.

=head1 Repository

L<SPVM::File::Temp - Github|https://github.com/yuki-kimoto/SPVM-File-Temp>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
