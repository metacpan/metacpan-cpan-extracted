use utf8;
package Music::Schema::Result::AlbumArtist;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Music::Schema::Result::AlbumArtist

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<album_artist>

=cut

__PACKAGE__->table("album_artist");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'album_artist_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 description

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "album_artist_id_seq",
  },
  "name",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "description",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 albums

Type: has_many

Related object: L<Music::Schema::Result::Album>

=cut

__PACKAGE__->has_many(
  "albums",
  "Music::Schema::Result::Album",
  { "foreign.album_artist" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-04-14 01:57:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WYeA4VuYwgEP2yyuh3iCWQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
