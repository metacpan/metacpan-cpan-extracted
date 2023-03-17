package SPVM::File::Find;

our $VERSION = '0.02';

1;

=head1 Name

SPVM::File::Find - Short Description

=head1 Description

C<SPVM::File::Find> is the C<File::Find> class in L<SPVM> language.

The C<File::Find> class has methods to get files under a directory.

=head1 Usage

  use File::Find;
  
  my $dir = "lib";
  
  my $files_list = StringList->new;
  
  File::Find->find([$files_list : StringList] method : void ($dir : string, $file_base_name : string) {
    my $file = $dir;
    if ($file_base_name) {
      $file .= "/$file_base_name";
    }
    
    warn "$file";
  }, $dir);

Gets file names:

  use File::Find;
  use StringList;
  
  my $dir = "lib";
  
  my $files_list = StringList->new;
  
  File::Find->find([$files_list : StringList] method : void ($dir : string, $file_base_name : string) {
    my $file = $dir;
    if ($file_base_name) {
      $file .= "/$file_base_name";
    }
    
    $files_list->push($file);
    
  }, $dir);
  
  my $files = $files_list->to_array;

=head1 Class Methods

  static method find : void ($cb : File::Find::Handler, $top_dir : string, $options = undef : object[]);

Iterates each file recursively under the $top_dir and calls the $cb by the file.

=head1 See also

=head2 File::Find

C<SPVM::File::Find> is a Perl's L<File::Find> porting to L<SPVM>.

=head1 Repository

L<SPVM::File::Find - Github|https://github.com/yuki-kimoto/SPVM-File-Find>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright 2023-2023 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

