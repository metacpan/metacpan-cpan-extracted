package SPVM::Mojo::Asset::Memory;



1;

=head1 Name

SPVM::Mojo::Asset::Memory - In-memory storage for HTTP content

=head1 Description

Mojo::Asset::Memory class in L<SPVM> has methods to do someting.

=head1 Usage

  use Mojo::Asset::Memory;
  
  my $mem = Mojo::Asset::Memory->new;
  $mem->add_chunk("foo bar baz");
  say $mem->slurp;

=head1 Super Class

L<Mojo::Asset|SPVM::Mojo::Asset>

=head1 Events

=head2 upgrade

  $mem->on(upgrade => method ($mem : Mojo::Asset::Memory, $file : Mojo::Asset::File) {...});

Emitted when asset gets upgraded to a L<Mojo::Asset::File|SPVM::Mojo::Asset::File> object.

  $mem->on(upgrade => method ($mem : Mojo::Asset::Memory, $file : Mojo::Asset::File) { $file->set_tmpdir("/tmp"); });

=head1 Fields

=head2 auto_upgrade

C<has auto_upgrade : rw byte;>

Try to detect if content size exceeds L</"max_memory_size"> limit and automatically upgrade to a L<Mojo::Asset::File|SPVM::Mojo::Asset::File>
object.

=head2 max_memory_size

C<has max_memory_size : rw int;>

Maximum size in bytes of data to keep in memory before automatically upgrading to a L<Mojo::Asset::File|SPVM::Mojo::Asset::File> object,
defaults to the value of the C<SPVM_MOJO_MAX_MEMORY_SIZE> environment variable or C<262144> (256KiB).

=head2 mtime

C<has mtime : rw long;>

Modification time of asset, defaults to the value of C<$^T>.

=head1 Class Methods

C<static method new : L<Mojo::Asset::Memory|SPVM::Mojo::Asset::Memory> ();>

Creates a new L<Mojo::Asset::Memory|SPVM::Mojo::Asset::Memory> object, and returns it.

=head1 Instance Methods

=head2 add_chunk

C<method add_chunk : Mojo::Asset ($chunk : string);>

Add chunk of data and upgrade to L<Mojo::Asset::File|SPVM::Mojo::Asset::File> object if necessary.

=head2 contains

C<method contains : int ($string : string);>

Check if asset contains a specific string.

=head2 get_chunk

C<method get_chunk : string ($offset : long, $max : int = -1);>

Get chunk of data starting from a specific position, defaults to a maximum chunk size of C<131072> bytes (128KiB).

=head2 move_to

C<method move_to : void ($file : string);>

Move asset data into a specific file.

=head2 size

C<method size : long ();>

Size of asset data in bytes.

=head2 slurp

C<method slurp : string ();>

Read all asset data at once.

=head2 to_file

C<method to_file : L<Mojo::Asset::File|SPVM::Mojo::Asset::File> ();>

Convert asset to L<Mojo::Asset::File|SPVM::Mojo::Asset::File> object.

=head1 See Also

=over 2

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

