package SPVM::File::Temp::Dir;

1;

=head1 Name

SPVM::File::Temp::Dir - Temporary Directories

=head1 Description

The File::Temp::Dir class in L<SPVM> has methods to manipulate temporary directories.

=head2 Usage
  
  use File::Temp;
  
  my $tmp_dir = File::Temp->newdir;
  
  my $tmp_dir_name = $tmp_dir->dirname;

=head1 Fields

C<has dirname : ro string;>

Returns the directory name.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
