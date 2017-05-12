package RackTables::Schema::Result::RackObject;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::RackObject

=cut

__PACKAGE__->table("RackObject");

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

=head2 label

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 objtype_id

  data_type: 'integer'
  default_value: 1
  extra: {unsigned => 1}
  is_nullable: 0

=head2 asset_no

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 has_problems

  data_type: 'enum'
  default_value: 'no'
  extra: {list => ["yes","no"]}
  is_nullable: 0

=head2 comment

  data_type: 'text'
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
  "label",
  { data_type => "char", is_nullable => 1, size => 255 },
  "objtype_id",
  {
    data_type => "integer",
    default_value => 1,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "asset_no",
  { data_type => "char", is_nullable => 1, size => 64 },
  "has_problems",
  {
    data_type => "enum",
    default_value => "no",
    extra => { list => ["yes", "no"] },
    is_nullable => 0,
  },
  "comment",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("RackObject_asset_no", ["asset_no"]);
__PACKAGE__->add_unique_constraint("name", ["name"]);

=head1 RELATIONS

=head2 attribute_values

Type: has_many

Related object: L<RackTables::Schema::Result::AttributeValue>

=cut

__PACKAGE__->has_many(
  "attribute_values",
  "RackTables::Schema::Result::AttributeValue",
  { "foreign.object_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cached_pvms

Type: has_many

Related object: L<RackTables::Schema::Result::CachedPVM>

=cut

__PACKAGE__->has_many(
  "cached_pvms",
  "RackTables::Schema::Result::CachedPVM",
  { "foreign.object_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cacti_graphs

Type: has_many

Related object: L<RackTables::Schema::Result::CactiGraph>

=cut

__PACKAGE__->has_many(
  "cacti_graphs",
  "RackTables::Schema::Result::CactiGraph",
  { "foreign.object_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ipv4_allocations

Type: has_many

Related object: L<RackTables::Schema::Result::IPv4Allocation>

=cut

__PACKAGE__->has_many(
  "ipv4_allocations",
  "RackTables::Schema::Result::IPv4Allocation",
  { "foreign.object_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ipv4_lbs

Type: has_many

Related object: L<RackTables::Schema::Result::IPv4LB>

=cut

__PACKAGE__->has_many(
  "ipv4_lbs",
  "RackTables::Schema::Result::IPv4LB",
  { "foreign.object_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ipv4_nats

Type: has_many

Related object: L<RackTables::Schema::Result::IPv4NAT>

=cut

__PACKAGE__->has_many(
  "ipv4_nats",
  "RackTables::Schema::Result::IPv4NAT",
  { "foreign.object_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ipv6_allocations

Type: has_many

Related object: L<RackTables::Schema::Result::IPv6Allocation>

=cut

__PACKAGE__->has_many(
  "ipv6_allocations",
  "RackTables::Schema::Result::IPv6Allocation",
  { "foreign.object_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mount_operations

Type: has_many

Related object: L<RackTables::Schema::Result::MountOperation>

=cut

__PACKAGE__->has_many(
  "mount_operations",
  "RackTables::Schema::Result::MountOperation",
  { "foreign.object_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 object_logs

Type: has_many

Related object: L<RackTables::Schema::Result::ObjectLog>

=cut

__PACKAGE__->has_many(
  "object_logs",
  "RackTables::Schema::Result::ObjectLog",
  { "foreign.object_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ports

Type: has_many

Related object: L<RackTables::Schema::Result::Port>

=cut

__PACKAGE__->has_many(
  "ports",
  "RackTables::Schema::Result::Port",
  { "foreign.object_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 rack_object_histories

Type: has_many

Related object: L<RackTables::Schema::Result::RackObjectHistory>

=cut

__PACKAGE__->has_many(
  "rack_object_histories",
  "RackTables::Schema::Result::RackObjectHistory",
  { "foreign.id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 rack_spaces

Type: has_many

Related object: L<RackTables::Schema::Result::RackSpace>

=cut

__PACKAGE__->has_many(
  "rack_spaces",
  "RackTables::Schema::Result::RackSpace",
  { "foreign.object_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vlanswitch

Type: might_have

Related object: L<RackTables::Schema::Result::VLANSwitch>

=cut

__PACKAGE__->might_have(
  "vlanswitch",
  "RackTables::Schema::Result::VLANSwitch",
  { "foreign.object_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vkWqX2fqXph1z2wJkuhB4w


# You can replace this text with custom code or comments, and it will be preserved on regeneration

=head2 dictionary

Type: might_have

Related object: L<RackTables::Schema::Result::Dictionary>

=cut

__PACKAGE__->might_have(dictionary =>
    "RackTables::Schema::Result::Dictionary",
    { "foreign.dict_key" => "self.objtype_id" },
    { cascade_copy => 0, cascade_delete => 0 },
);


__PACKAGE__->meta->make_immutable;

