package SPVM::File::Temp;

our $VERSION = "0.028";

1;

=head1 Name

SPVM::File::Temp - Temporary Files and Directories

=head1 Description

File::Temp class in L<SPVM> has methods to create temporary files and directories.

=head1 Usage

  use File::Temp;
  
  # Create a temporary file
  my $tmp_fh = File::Temp->new;
  
  my $tmp_filename = $tmp_fh->filename;
  
  $tmp_fh->print("Hello World!");
  
  # With options
  my $tmp_fh = File::Temp->new({DIR => $dir, TEMPLATE => $template, UNLINK => 0});
  
  # Create a temporary directory
  my $tmp_dir = File::Temp->newdir;
  
  my $tmp_dirname = $tmp_dir->dirname;

=head1 Super Class

L<IO::File>

=head1 Fields

=head2 filename

C<has filename : ro string;>

A file path. This is the path of a temporary file.

=head2 process_id

C<has process_id : int;>

A process ID. This is the process ID of the process that creates a temporary file.

=head1 Class Methods

=head2 new

C<static method new : L<File::Temp|SPVM::File::Temp> ($options : object[] = undef);>

Creates a new L<File::Temp|SPVM::File::Temp> object given the options $options, and returns it.

L</"process_id"> field is set to the current process ID.

=head3 new Options

=head4 DIR option

C<DIR> : string = undef

A directory where a temproary file is created.

=head4 TMPDIR option

C<TMPDIR> : L<Int|SPVM::Int> = 0

If this value is a true value and the value of L</"TEMPLATE option"> is defined but the value of L</"DIR option"> is not defined, the temporary directory in the system is used as the value of L</"DIR option">.

=head4 TEMPLATE option

C<TEMPLATE> : string = undef

A template. This is the template for the base name of the temporary file and contains multiple C<X> such as C<tempXXXXX>.

Note:

If the value of this option is defined and the value of L</"DIR"> option is not defined and the value of L</"TMPDIR"> option is not a true value, a temporary file is created in the current working directry.

=head4 SUFFIX option

C<SUFFIX> : string = ""

An extension of the temprary file such as C<.tmp>.

=head4 UNLINK option

C<UNLINK> : L<Int|SPVM::Int> = 1

If this value is a true value, the program tries to remove the temporary file when this instance is destroyed.

See L</"DESTROY"> method for details.

=head2 newdir

C<static method newdir : L<File::Temp::Dir|SPVM::File::Temp::Dir> ($options : object[] = undef);>

Calls L<File::Temp::Dir#new|SPVM::File::Temp::Dir/new> method given the options $options, and retunrs its return value.

=head2 DESTROY

C<method DESTROY : void ();>

If the file handle is opened, closes the file descriptor of the temporary file.

If the vlaue of L</"UNLINK option"> is a true value and the current process ID is the same as L</"process_id"> field, removes the temproary file.

=head1 Repository

L<SPVM::File::Temp - Github|https://github.com/yuki-kimoto/SPVM-File-Temp>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
