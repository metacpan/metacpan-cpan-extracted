package RackTables::Schema::Result::VLANDescription;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::VLANDescription

=cut

__PACKAGE__->table("VLANDescription");

=head1 ACCESSORS

=head2 domain_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 vlan_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 vlan_type

  data_type: 'enum'
  default_value: 'ondemand'
  extra: {list => ["ondemand","compulsory","alien"]}
  is_nullable: 0

=head2 vlan_descr

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "domain_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "vlan_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "vlan_type",
  {
    data_type => "enum",
    default_value => "ondemand",
    extra => { list => ["ondemand", "compulsory", "alien"] },
    is_nullable => 0,
  },
  "vlan_descr",
  { data_type => "char", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("domain_id", "vlan_id");

=head1 RELATIONS

=head2 domain

Type: belongs_to

Related object: L<RackTables::Schema::Result::VLANDomain>

=cut

__PACKAGE__->belongs_to(
  "domain",
  "RackTables::Schema::Result::VLANDomain",
  { id => "domain_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 vlan

Type: belongs_to

Related object: L<RackTables::Schema::Result::VLANValidID>

=cut

__PACKAGE__->belongs_to(
  "vlan",
  "RackTables::Schema::Result::VLANValidID",
  { vlan_id => "vlan_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 vlanipv4s

Type: has_many

Related object: L<RackTables::Schema::Result::VLANIPv4>

=cut

__PACKAGE__->has_many(
  "vlanipv4s",
  "RackTables::Schema::Result::VLANIPv4",
  {
    "foreign.domain_id" => "self.domain_id",
    "foreign.vlan_id"   => "self.vlan_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vlanipv6s

Type: has_many

Related object: L<RackTables::Schema::Result::VLANIPv6>

=cut

__PACKAGE__->has_many(
  "vlanipv6s",
  "RackTables::Schema::Result::VLANIPv6",
  {
    "foreign.domain_id" => "self.domain_id",
    "foreign.vlan_id"   => "self.vlan_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8fV30Njk6wVuRkdKSbAefg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
