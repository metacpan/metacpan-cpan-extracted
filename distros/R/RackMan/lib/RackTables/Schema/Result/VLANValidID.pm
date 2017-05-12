package RackTables::Schema::Result::VLANValidID;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::VLANValidID

=cut

__PACKAGE__->table("VLANValidID");

=head1 ACCESSORS

=head2 vlan_id

  data_type: 'integer'
  default_value: 1
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "vlan_id",
  {
    data_type => "integer",
    default_value => 1,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("vlan_id");

=head1 RELATIONS

=head2 cached_pavs

Type: has_many

Related object: L<RackTables::Schema::Result::CachedPAV>

=cut

__PACKAGE__->has_many(
  "cached_pavs",
  "RackTables::Schema::Result::CachedPAV",
  { "foreign.vlan_id" => "self.vlan_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 port_allowed_vlans

Type: has_many

Related object: L<RackTables::Schema::Result::PortAllowedVLAN>

=cut

__PACKAGE__->has_many(
  "port_allowed_vlans",
  "RackTables::Schema::Result::PortAllowedVLAN",
  { "foreign.vlan_id" => "self.vlan_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vlandescriptions

Type: has_many

Related object: L<RackTables::Schema::Result::VLANDescription>

=cut

__PACKAGE__->has_many(
  "vlandescriptions",
  "RackTables::Schema::Result::VLANDescription",
  { "foreign.vlan_id" => "self.vlan_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uvgo0hbzuYz6w0qvHQuUgg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
