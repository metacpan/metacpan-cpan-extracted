package RackTables::Schema::Result::AttributeValue;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::AttributeValue

=cut

__PACKAGE__->table("AttributeValue");

=head1 ACCESSORS

=head2 object_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 attr_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 string_value

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 uint_value

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 float_value

  data_type: 'float'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "object_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "attr_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "string_value",
  { data_type => "char", is_nullable => 1, size => 255 },
  "uint_value",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "float_value",
  { data_type => "float", is_nullable => 1 },
);
__PACKAGE__->add_unique_constraint("object_id", ["object_id", "attr_id"]);

=head1 RELATIONS

=head2 attr

Type: belongs_to

Related object: L<RackTables::Schema::Result::AttributeMap>

=cut

__PACKAGE__->belongs_to(
  "attr",
  "RackTables::Schema::Result::AttributeMap",
  { attr_id => "attr_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 object

Type: belongs_to

Related object: L<RackTables::Schema::Result::RackObject>

=cut

__PACKAGE__->belongs_to(
  "object",
  "RackTables::Schema::Result::RackObject",
  { id => "object_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Qca1PyaO19TdNK0RCgjaAw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;

# declare a primary key
__PACKAGE__->set_primary_key("attr_id");


1;
