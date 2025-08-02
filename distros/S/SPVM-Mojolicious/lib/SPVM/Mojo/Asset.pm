package SPVM::Mojo::Asset;



1;

=head1 Name

SPVM::Mojo::Asset - HTTP content storage base class

=head1 Description

Mojo::Asset class in L<SPVM> an abstract base class for HTTP content storage backends, like L<Mojo::Asset::File|SPVM::Mojo::Asset::File> and
L<Mojo::Asset::Memory|SPVM::Mojo::Asset::Memory>.

=head1 Usage

  use Mojo::Asset;
  
  class Mojo::Asset::MyAsset extends Mojo::Asset {
    
  }

=head1 Fields

=head2 end_range

C<has end_range : rw long;>

Pretend file ends earlier.

=head2 start_range

C<has start_range : rw long;>

Pretend file starts later.

=head1 Instance Methods

=head2 add_chunk

C<method add_chunk : Mojo::Asset ($chunk : string);>

Add chunk of data to asset. Meant to be overloaded in a subclass.

=head2 contains

C<method contains : int ($string : string);>

Check if asset contains a specific string. Meant to be overloaded in a subclass.

=head2 get_chunk

C<method get_chunk : string ($offset : long, $max : int = -1);>

Get chunk of data starting from a specific position, defaults to a maximum chunk size of C<131072> bytes (128KiB).
Meant to be overloaded in a subclass.

=head2 is_file

C<method is_file : int ();>

False, this is not a L<Mojo::Asset::File|SPVM::Mojo::Asset::File> object.

=head2 is_range

C<method is_range : int ();>

Check if asset has a L</"start_range"> or L</"end_range">.

=head2 move_to

C<method move_to : void ($file : string);>

Move asset data into a specific file. Meant to be overloaded in a subclass.

=head2 mtime

C<method mtime : long ();>

Modification time of asset. Meant to be overloaded in a subclass.

=head2 set_mtime

C<method set_mtime : void ($mtime : long);>

Set modification time of asset. Meant to be overloaded in a subclass.

=head2 size

C<method size : long ();>

Size of asset data in bytes. Meant to be overloaded in a subclass.

=head2 slurp

C<method slurp : string ();>

Read all asset data at once. Meant to be overloaded in a subclass.

=head2 to_file

C<method to_file : Mojo::Asset::File ();>

Convert asset to L<Mojo::Asset::File|SPVM::Mojo::Asset::File> object. Meant to be overloaded in a subclass.

=head1 Well Known Child Classes

=over 2

=item * L<Mojo::Asset::Memory|SPVM::Mojo::Asset::Memory>

=item * L<Mojo::Asset::File|SPVM::Mojo::Asset::File>

=back

=head1 See Also

=over 2

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

