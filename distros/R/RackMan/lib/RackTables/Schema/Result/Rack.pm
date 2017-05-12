package RackTables::Schema::Result::Rack;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::Rack

=cut

__PACKAGE__->table("Rack");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 row_id

  data_type: 'integer'
  default_value: 1
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 height

  data_type: 'tinyint'
  default_value: 42
  extra: {unsigned => 1}
  is_nullable: 0

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 thumb_data

  data_type: 'blob'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "char", is_nullable => 1, size => 255 },
  "row_id",
  {
    data_type => "integer",
    default_value => 1,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "height",
  {
    data_type => "tinyint",
    default_value => 42,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "thumb_data",
  { data_type => "blob", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("name_in_row", ["row_id", "name"]);

=head1 RELATIONS

=head2 row

Type: belongs_to

Related object: L<RackTables::Schema::Result::RackRow>

=cut

__PACKAGE__->belongs_to(
  "row",
  "RackTables::Schema::Result::RackRow",
  { id => "row_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 rack_spaces

Type: has_many

Related object: L<RackTables::Schema::Result::RackSpace>

=cut

__PACKAGE__->has_many(
  "rack_spaces",
  "RackTables::Schema::Result::RackSpace",
  { "foreign.rack_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:M/7KHhuNcqu32rfclM6+jg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
