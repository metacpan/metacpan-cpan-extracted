use utf8;
package Music::Schema::Result::Song;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Music::Schema::Result::Song

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<song>

=cut

__PACKAGE__->table("song");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'song_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 album

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 track

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "song_id_seq",
  },
  "name",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "album",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "track",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 album

Type: belongs_to

Related object: L<Music::Schema::Result::Album>

=cut

__PACKAGE__->belongs_to(
  "album",
  "Music::Schema::Result::Album",
  { id => "album" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-04-14 01:57:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4WyUnt+EMGO7ShWIt5OiMg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
