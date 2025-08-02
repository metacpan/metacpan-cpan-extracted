package SPVM::Mojo::Asset::File;



1;

=head1 Name

SPVM::Mojo::Asset::File - File storage for HTTP content

=head1 Description

Mojo::Asset::File class in L<SPVM> is a file storage backend for HTTP content.

=head1 Usage

  use Mojo::Asset::File;
  
  # Temporary file
  my $file = Mojo::Asset::File->new;
  $file->add_chunk("foo bar baz");
  if ($file->contains("bar") >= 0) {
    say "File contains \"bar\"" ;
  }
  say $file->slurp;
  
  # Existing file
  my $file = Mojo::Asset::File->new;
  $file->set_path("/home/sri/foo.txt");
  $file->move_to("/yada.txt");
  say $file->slurp;

=head1 Fields

=head2 cleanup

C<has cleanup : rw byte;>

Delete L</"path"> automatically once the file is not used anymore.

=head2 path

C<has path : rw string;>

Filehandle, created on demand for L</"path">, which can be generated automatically and safely based on L</"tmpdir">.

=head2 handle

C<has handle : rw IO::File;>

File path used to create L</"handle">.

=head2 tmpdir

C<has tmpdir : rw string;>

Temporary directory used to generate L</"path">, defaults to the value of the C<MOJO_TMPDIR> environment variable or
auto-detection.

=head1 Class Methods

=head2 new

C<static method new : L<Mojo::Asset::File|SPVM::Mojo::Asset::File> ();>

Creates a new L<Mojo::Asset::File|SPVM::Mojo::Asset::File> object, and returns it.

=head1 Instance Methods

=head2 add_chunk

C<method add_chunk : L<Mojo::Asset::File|SPVM::Mojo::Asset::File> ($chunk : string);>

Add chunk of data.

=head2 contains

C<method contains : int ($string : string);>

Check if asset contains a specific string.

=head2 get_chunk

C<method get_chunk : string ($offset : long, $max : int = -1);>

Get chunk of data starting from a specific position, defaults to a maximum chunk size of C<131072> bytes (128KiB).

=head2 is_file

C<method is_file : int ();>

True, this is a L<Mojo::Asset::File|SPVM::Mojo::Asset::File> object.

=head2 move_to

C<method move_to : void ($file : string);>

Move asset data into a specific file and disable L</"cleanup">.

=head2 mtime

C<method mtime : long ();>

Modification time of asset.

=head2 size

C<method size : long ();>

Size of asset data in bytes.

=head2 slurp

C<method slurp : string ();>

Read all asset data at once.

=head2 to_file

C<method to_file : L<Mojo::Asset::File|SPVM::Mojo::Asset::File> ();>

Does nothing but return the invocant, since we already have a L<Mojo::Asset::File|SPVM::Mojo::Asset::File> object.

=head1 See Also

=over 2

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

