package SPVM::Mojo::File;



1;

=head1 Name

SPVM::Mojo::File - File system paths

=head1 Description

Mojo::File class in L<SPVM> is a scalar-based container for file system paths that provides a friendly API for dealing with different
operating systems.

=head1 Usage

  use Mojo::File;

  # Portably deal with file system paths
  my $path = Mojo::File->new("/home/sri/.vimrc");
  say $path->slurp;
  say $path->dirname->to_string;
  say $path->basename;
  say $path->extname;
  say $path->sibling(".bashrc")->to_string;

  # Use the alternative constructor
  my $path = Mojo::File->new("/tmp/foo/bar")
  $path->make_path;
  $path->child("test.txt")->spew("Hello Mojo!");

=head1 Interfaces

=over 2

=item * L<Stringable|SPVM::Stringable>

=back

=head1 Fields

=head2 file

C<has file : rw object of string|L<File::Temp|SPVM::File::Temp>|L<File::Temp::Dir|SPVM::File::Temp::Dir>;>

A file path or an object with a file path.

Examples:

  # Access scalar directly to manipulate path
  my $path = Mojo::File->new("/home/sri/test");
  $path->set_file($path->file . ".txt");

=head1 Class Methods

=head2 new

C<static method new : L<Mojo::File|SPVM::Mojo::File> ($file : object of string|string[]|L<File::Temp|SPVM::File::Temp>|L<File::Temp::Dir|SPVM::File::Temp::Dir>);>

Construct a new L<Mojo::File|SPVM::Mojo::File> object, defaults to using the current working directory.

Examples:

  # "foo/bar/baz.txt" (on UNIX)
  Mojo::File->new(["foo", "bar", "baz.txt"]);
  
  my $path = Mojo::File->new;
  my $path = Mojo::File->new("/home/sri/.vimrc");
  my $path = Mojo::File->new(["/home", "sri", ".vimrc"]);
  my $path = Mojo::File->new(File::Temp->new);
  my $path = Mojo::File->new(File::Temp->newdir);

=head2 tempdir

C<static method tempdir : L<Mojo::File|SPVM::Mojo::File> ($options : object[] = undef);>

Construct a new scalar-based L<Mojo::File|SPVM::Mojo::File> object for a temporary directory with L<File::Temp|SPVM::File::Temp>.

Examples:

  my $path = Mojo::File->tempdir;
  my $path = Mojo::File->tempdir({TEMPLATE => "tempXXXXX"});
  
  # Longer version
  my $path = Mojo::File->new(File::Temp->newdir(TEMPLATE => "tempXXXXX"));

=head2 tempfile

C<static method tempfile : L<Mojo::File|SPVM::Mojo::File> ($options : object[] = undef);>

Construct a new scalar-based L<Mojo::File|SPVM::Mojo::File> object for a temporary file with L<File::Temp|SPVM::File::Temp>.

  my $path = Mojo::File->tempfile;
  my $path = Mojo::File->tempfile({DIR => "/tmp"});
  
  # Longer version
  my $path = Mojo::File->new(File::Temp->new({DIR => "/tmp"}));

=head2 path

C<static method path : L<Mojo::File|SPVM::Mojo::File> ($file : object of string|string[]|L<File::Temp|SPVM::File::Temp>|L<File::Temp::Dir|SPVM::File::Temp::Dir>);>

Alias for L</"new"> method.

=head1 Instance Methods

=head2 basename

C<method basename : string ();>

Return the last level of the path with L<File::Basename|SPVM::File::Basename>.

Exmaples:

  # ".vimrc" (on UNIX)
  Mojo::File->new("/home/sri/.vimrc")->basename;

=head2 child

C<method child : L<Mojo::File|SPVM::Mojo::File> ($base_name : object of string|string[]);>

Return a new L<Mojo::File|SPVM::Mojo::File> object relative to the path.

Examples:

  Mojo::Path->new("/home")->child(".vimrc");
  
  # "/home/sri/.vimrc" (on UNIX)
  Mojo::Path->new("/home")->child("sri", ".vimrc");

=head2 chmod

C<method chmod : void ($mode : int);>

Change file permissions.

Examples:

  $path->chmod(0644);

=head2 copy_to

C<method copy_to : L<Mojo::File|SPVM::Mojo::File> ($to : string);>

Copy file with L<File::Copy|SPVM::File::Copy> and return the destination as a L<Mojo::File|SPVM::Mojo::File> object.

Examples:

  my $destination = $path->copy_to("/home/sri");
  my $destination = $path->copy_to("/home/sri/.vimrc.backup");

=head2 dirname

C<method dirname : L<Mojo::File|SPVM::Mojo::File> ();>

Return all but the last level of the path with L<File::Basename|SPVM::File::Basename> as a L<Mojo::File|SPVM::Mojo::File> object.

Examples:

  # "/home/sri" (on UNIX)
  Mojo::Path->new("/home/sri/.vimrc")->dirname;

=head2 extname

C<method extname : string ();>

Return file extension of the path.

Examples:

  my $ext = $path->extname;
  
  # "js"
  Mojo::Path->new("/home/sri/test.js")->extname;

=head2 is_abs

C<method is_abs : int ();>

Check if the path is absolute.

Examples:

  my $bool = $path->is_abs;

  # True (on UNIX)
  Mojo::Path->new("/home/sri/.vimrc")->is_abs;

  # False (on UNIX)
  Mojo::Path->new(".vimrc")->is_abs;

=head2 list

C<method list : Mojo::Collection ($options : object[] = undef);>

List all files in the directory and return a L<Mojo::Collection|SPVM::Mojo::Collection> object containing the results as L<Mojo::File|SPVM::Mojo::File>
objects. The list does not include C<.> and C<..>.

Examples:

  my $collection = $path->list;
  my $collection = $path->list({hidden => 1});
  
  # List files
  for my $_ (@{(Mojo::File[])Mojo::File->new("/home/sri/myapp")->list->to_array}) {
    say $_->to_string;
  }

These options are currently available:

=over 2

=item dir

  dir => 1

Include directories.

=item hidden

  hidden => 1

Include hidden files.

=back

=head2 list_tree

C<method list_tree : Mojo::Collection ($options : object[] = undef);>

List all files recursively in the directory and return a L<Mojo::Collection|SPVM::Mojo::Collection> object containing the results as
L<Mojo::File|SPVM::Mojo::File> objects. The list does not include C<.> and C<..>.

Examples:

  my $collection = $path->list_tree;
  my $collection = $path->list_tree({hidden => 1});
  
  # List files
  for my $_ (@{(Mojo::File[])Mojo::File->new("/home/sri/myapp/templates")->list_tree->to_array}) {
    say $_->to_string;
  }

These options are currently available:

=over 2

=item dir

  dir => 1

Include directories.

=item hidden

  hidden => 1

Include hidden files and directories.

=item max_depth

  max_depth => 3

Maximum number of levels to descend when searching for files.

=back

=head2 lstat

C<method lstat : Sys::IO::Stat ();>

Return a L<Sys::IO::Stat|SPVM::Sys::IO::Stat> object for the symlink.

Examples:

  my $stat = $path->lstat;

  # Get symlink size
  say Mojo::Path->new("/usr/sbin/sendmail")->lstat->size;

  # Get symlink modification time
  say Mojo::Path->new("/usr/sbin/sendmail")->lstat->mtime;

=head2 make_path

C<method make_path : void ($options : object[] = undef);>

Create the directories if they don"t already exist, any additional arguments are passed through to L<File::Path|SPVM::File::Path>.

Examples:

  $path->make_path;
  $path->make_path({mode => 0711});

=head2 move_to

C<method move_to : L<Mojo::File|SPVM::Mojo::File> ($to : string);>

Examples:

  my $destination = $path->move_to("/home/sri");
  my $destination = $path->move_to("/home/sri/.vimrc.backup");

Move file with L<File::Copy|SPVM::File::Copy> and return the destination as a L<Mojo::File|SPVM::Mojo::File> object.

=head2 open

C<method open : IO::File ($mode : object of string|Int)>

Open file with L<IO::File|SPVM::IO::File>.

Examples:
  
  use Sys::IO::Constant as IOC;
  
  my $handle = $path->open("<");
  my $handle = $path->open("r+");
  my $handle = $path->open(IOC->O_RDWR);

=head2 realpath

C<method realpath : L<Mojo::File|SPVM::Mojo::File> ();>

Resolve the path with L<Cwd|SPVM::Cwd> and return the result as a L<Mojo::File|SPVM::Mojo::File> object.

Examples:

  my $realpath = $path->realpath;

=head2 remove

C<method remove : void ();>

Delete file.

Examples:

  $path->remove;

=head2 remove_tree

C<method remove_tree : void ($options : object[] = undef);>

Delete this directory and any files and subdirectories it may contain, any additional arguments are passed through to
L<File::Path|SPVM::File::Path>.

Examples:

  $path->remove_tree;

=head2 sibling

C<method sibling : L<Mojo::File|SPVM::Mojo::File> ($base_name : object of string|stirng[]);>

Return a new L<Mojo::File|SPVM::Mojo::File> object relative to the directory part of the path.

Examples:

  my $sibling = $path->sibling(".vimrc");

  # "/home/sri/.vimrc" (on UNIX)
  Mojo::Path->new("/home/sri/.bashrc")->sibling(".vimrc");

  # "/home/sri/.ssh/known_hosts" (on UNIX)
  Mojo::Path->new("/home/sri/.bashrc")->sibling([".ssh", "known_hosts"]);

=head2 slurp

C<method slurp : string ();>

Read all data at once from the file. If an encoding is provided, an attempt will be made to decode the content.

Examples:

  my $bytes = $path->slurp;

=head2 spew

C<method spew : void ($content : string);>

Write all data at once to the file. If an encoding is provided, an attempt to encode the content will be made prior to
writing.

Examples:

  $path->spew($bytes);

=head2 stat

C<method stat : Sys::IO::Stat ();>

Return a L<Sys::IO::Stat|SPVM::Sys::IO::Stat> object for the path.

Examples:

  # Get file size
  say Mojo::Path->new("/home/sri/.bashrc")->stat->size;

  # Get file modification time
  say Mojo::Path->new("/home/sri/.bashrc")->stat->mtime;

=head2 to_abs

C<method to_abs : L<Mojo::File|SPVM::Mojo::File> ();>

Return absolute path as a L<Mojo::File|SPVM::Mojo::File> object, the path does not need to exist on the file system.

Examples:

  my $absolute = $path->to_abs;

=head2 to_array

C<method to_array : string[] ();>

Split the path on directory separators.

Examples:

  # "home:sri:.vimrc" (on UNIX)
  Fn->join(":", Mojo::File->new("/home/sri/.vimrc")->to_array);

=head2 to_rel

C<method to_rel : L<Mojo::File|SPVM::Mojo::File> ($rel_file : string);>

Return a relative path from the original path to the destination path as a L<Mojo::File|SPVM::Mojo::File> object.

Examples:

  my $relative = $path->to_rel("/some/base/path");

  # "sri/.vimrc" (on UNIX)
  Mojo::Path->new("/home/sri/.vimrc")->to_rel("/home");

=head2 to_string

C<method to_string : string ();>

Stringify the path.

Examples:

  my $str = $path->to_string;

=head2 touch

C<method touch : void ();>

Create file if it does not exist or change the modification and access time to the current time.

Examples:

  $path->touch;

  # Safely read file
  my $path = Mojo::Path->new(".bashrc");
  $path->touch;
  say $path->slurp;

=head1 See Also

=over 2

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

