use utf8;
package Music::Schema::Result::Album;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Music::Schema::Result::Album

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<album>

=cut

__PACKAGE__->table("album");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'album_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 album_artist

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 year

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "album_id_seq",
  },
  "name",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "album_artist",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "year",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 album_artist

Type: belongs_to

Related object: L<Music::Schema::Result::AlbumArtist>

=cut

__PACKAGE__->belongs_to(
  "album_artist",
  "Music::Schema::Result::AlbumArtist",
  { id => "album_artist" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 songs

Type: has_many

Related object: L<Music::Schema::Result::Song>

=cut

__PACKAGE__->has_many(
  "songs",
  "Music::Schema::Result::Song",
  { "foreign.album" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-04-14 01:57:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lCUoT9PfC5uO7okII0puvw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
