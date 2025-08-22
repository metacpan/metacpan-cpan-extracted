package SPVM::Mojo::Upload;



1;

=head1 Name

SPVM::Mojo::Upload - Upload

=head1 Description

Mojo::Upload class in L<SPVM> a container for uploaded files.

=head1 Usage

  use Mojo::Upload;
  
  my $upload = Mojo::Upload->new;
  say $upload->filename;
  $upload->move_to("/home/sri/foo.txt");

=head1 Fields

=head2 asset

C<has asset : rw L<Mojo::Asset|SPVM::Mojo::Asset>;>

Asset containing the uploaded data, usually a L<Mojo::Asset::File|SPVM::Mojo::Asset::File> or L<Mojo::Asset::Memory|SPVM::Mojo::Asset::Memory> object.

=head2 filename

C<has filename : rw string;>

Name of the uploaded file.

=head2 headers

C<has headers : rw L<Mojo::Headers|SPVM::Mojo::Headers>;>

Headers for upload, usually a L<Mojo::Headers|SPVM::Mojo::Headers> object.

=head2 name

C<has name : rw string;>

Name of the upload.

=head1 Class Methods

=head2 new

C<static method new : L<Mojo::Upload|SPVM::Mojo::Upload> ();>

Create a new L<Mojo::Upload|SPVM::Mojo::Upload> object, and return it.

=head1 Instance Methods

=head2 move_to

C<method move_to : void  ($to : string);>

=head2 size

C<method size : long ();>

=head2 slurp

C<method slurp : string ();>

=head1 See Also

=over 2

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License
