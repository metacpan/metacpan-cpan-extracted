use utf8;
package TestDB::Result::Rsschannel;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Strehler::Schema::RSS::Result::Rsschannel

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<RSSCHANNELS>

=cut

__PACKAGE__->table("RSSCHANNELS");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 link

  data_type: 'varchar'
  is_nullable: 1
  size: 120

=head2 entity_type

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 category

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 deep

  data_type: 'tinyint'
  is_nullable: 1

=head2 title_field

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 description_field

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 link_field

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 link_template

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 order_by

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 published

  data_type: 'tinyint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "link",
  { data_type => "varchar", is_nullable => 1, size => 120 },
  "entity_type",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "category",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "deep",
  { data_type => "tinyint", is_nullable => 1 },
  "title_field",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "description_field",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "link_field",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "link_template",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "order_by",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "published",
  { data_type => "tinyint", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 category

Type: belongs_to

Related object: L<Strehler::Schema::RSS::Result::Category>

=cut

__PACKAGE__->belongs_to(
  "category",
  "TestDB::Result::Category",
  { id => "category" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

=head2 rsschannel_headers

Type: has_many

Related object: L<Strehler::Schema::RSS::Result::RsschannelHeader>

=cut

__PACKAGE__->has_many(
  "rsschannel_headers",
  "TestDB::Result::RsschannelHeader",
  { "foreign.rsschannel" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2015-06-10 19:30:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:o4LDBRYojYLHoaiH7WwKsw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
