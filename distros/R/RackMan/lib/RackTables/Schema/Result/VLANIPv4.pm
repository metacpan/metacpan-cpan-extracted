package RackTables::Schema::Result::VLANIPv4;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::VLANIPv4

=cut

__PACKAGE__->table("VLANIPv4");

=head1 ACCESSORS

=head2 domain_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 vlan_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 ipv4net_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

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
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "ipv4net_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->add_unique_constraint("network-domain", ["ipv4net_id", "domain_id"]);

=head1 RELATIONS

=head2 vlandescription

Type: belongs_to

Related object: L<RackTables::Schema::Result::VLANDescription>

=cut

__PACKAGE__->belongs_to(
  "vlandescription",
  "RackTables::Schema::Result::VLANDescription",
  { domain_id => "domain_id", vlan_id => "vlan_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 ipv4net

Type: belongs_to

Related object: L<RackTables::Schema::Result::IPv4Network>

=cut

__PACKAGE__->belongs_to(
  "ipv4net",
  "RackTables::Schema::Result::IPv4Network",
  { id => "ipv4net_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pJo/2+v+4Uh53dzi2Kd23w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
