package RackTables::Schema::Result::PortVLANMode;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::PortVLANMode

=cut

__PACKAGE__->table("PortVLANMode");

=head1 ACCESSORS

=head2 object_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 port_name

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 255

=head2 vlan_mode

  data_type: 'enum'
  default_value: 'access'
  extra: {list => ["access","trunk"]}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "object_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "port_name",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 255 },
  "vlan_mode",
  {
    data_type => "enum",
    default_value => "access",
    extra => { list => ["access", "trunk"] },
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("object_id", "port_name");

=head1 RELATIONS

=head2 port_allowed_vlans

Type: has_many

Related object: L<RackTables::Schema::Result::PortAllowedVLAN>

=cut

__PACKAGE__->has_many(
  "port_allowed_vlans",
  "RackTables::Schema::Result::PortAllowedVLAN",
  {
    "foreign.object_id" => "self.object_id",
    "foreign.port_name" => "self.port_name",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cached_pvm

Type: belongs_to

Related object: L<RackTables::Schema::Result::CachedPVM>

=cut

__PACKAGE__->belongs_to(
  "cached_pvm",
  "RackTables::Schema::Result::CachedPVM",
  { object_id => "object_id", port_name => "port_name" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NlkmUOi3N4WwyOWxXSMDwA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
