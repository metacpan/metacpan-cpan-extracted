package SPVM::File::Temp::Dir;

1;

=head1 Name

SPVM::File::Temp::Dir - Temporary Directories

=head1 Description

The File::Temp::Dir class in L<SPVM> has methods to manipulate temporary directories.

=head2 Usage
  
  use File::Temp;
  
  my $tmp_dir = File::Temp::Dir->new;
  
  my $tmp_dirname = $tmp_dir->dirname;
  
  # With options
  my $tmp_dir = File::Temp::Dir->new({CLEANUP => 0});

=head1 Fields

=head2 dirname

C<has dirname : ro string;>

A directory path. This is the path of a temporary directoy.

=head2 process_id

C<has process_id : int;>

A process ID. This is the process ID of the process that creates a temporary directory.

=head1 Class Methods

=head2 new

C<static method new : L<File::Temp::Dir|SPVM::File::Temp::Dir> ($options : object[] = undef);>

Creates a new L<File::Temp::Dir|SPVM::File::Temp::Dir> object given the options $options, and returns it.

L</"process_id"> field is set to the current process ID.

=head3 new Options

=head4 DIR option

C<DIR> : string = undef

A directory where a temproary directory is created.

=head4 TMPDIR option

C<TMPDIR> : L<Int|SPVM::Int> = 0

If this value is a true value and the value of L</"TEMPLATE option"> is defined but the value of L</"DIR option"> is not defined, the temporary directory in the system is used as the value of L</"DIR option">.

=head4 TEMPLATE option

C<TEMPLATE> : string = undef

A template. This is the template for the base name of the temporary direcoty and contains multiple C<X> such as C<tempXXXXX>.

Note:

If the value of this option is defined and the value of L</"DIR"> option is not defined and the value of L</"TMPDIR"> option is not a true value, a temporary directiry is created in the current working directry.

=head4 CLEANUP option

C<CLEANUP> : L<Int|SPVM::Int> = 1

If this value is a true value, the program tries to remove the temporary directory when this instance is destroyed.

See L</"DESTROY"> method for details.

=head2 DESTROY

C<method DESTROY : void ();>

If the vlaue of L</"CLEANUP option"> is a true value and the current process ID is the same as L</"process_id"> field, removes the temproary directory.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
