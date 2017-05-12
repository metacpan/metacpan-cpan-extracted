package RackTables::Schema::Result::AttributeMap;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::AttributeMap

=cut

__PACKAGE__->table("AttributeMap");

=head1 ACCESSORS

=head2 objtype_id

  data_type: 'integer'
  default_value: 1
  extra: {unsigned => 1}
  is_nullable: 0

=head2 attr_id

  data_type: 'integer'
  default_value: 1
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 chapter_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "objtype_id",
  {
    data_type => "integer",
    default_value => 1,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "attr_id",
  {
    data_type => "integer",
    default_value => 1,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "chapter_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
);
__PACKAGE__->add_unique_constraint("objtype_id", ["objtype_id", "attr_id"]);

=head1 RELATIONS

=head2 attr

Type: belongs_to

Related object: L<RackTables::Schema::Result::Attribute>

=cut

__PACKAGE__->belongs_to(
  "attr",
  "RackTables::Schema::Result::Attribute",
  { id => "attr_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 attribute_values

Type: has_many

Related object: L<RackTables::Schema::Result::AttributeValue>

=cut

__PACKAGE__->has_many(
  "attribute_values",
  "RackTables::Schema::Result::AttributeValue",
  { "foreign.attr_id" => "self.attr_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:b4V5EhZXnAdHfuRs31A4AA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;

# declare primary keys
__PACKAGE__->set_primary_key(qw< objtype_id attr_id >);

# hidden relationship
__PACKAGE__->belongs_to(
    chapter => "RackTables::Result::Chapter",
    { id => "chapter_id" },
);


1;
