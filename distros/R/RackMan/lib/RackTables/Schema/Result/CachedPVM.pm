package RackTables::Schema::Result::CachedPVM;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::CachedPVM

=cut

__PACKAGE__->table("CachedPVM");

=head1 ACCESSORS

=head2 object_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 port_name

  data_type: 'char'
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
  { data_type => "char", is_nullable => 0, size => 255 },
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

=head2 cached_pavs

Type: has_many

Related object: L<RackTables::Schema::Result::CachedPAV>

=cut

__PACKAGE__->has_many(
  "cached_pavs",
  "RackTables::Schema::Result::CachedPAV",
  {
    "foreign.object_id" => "self.object_id",
    "foreign.port_name" => "self.port_name",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 object

Type: belongs_to

Related object: L<RackTables::Schema::Result::RackObject>

=cut

__PACKAGE__->belongs_to(
  "object",
  "RackTables::Schema::Result::RackObject",
  { id => "object_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 port_vlanmode

Type: might_have

Related object: L<RackTables::Schema::Result::PortVLANMode>

=cut

__PACKAGE__->might_have(
  "port_vlanmode",
  "RackTables::Schema::Result::PortVLANMode",
  {
    "foreign.object_id" => "self.object_id",
    "foreign.port_name" => "self.port_name",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PpPCh1ckEv1NO1piCEYl8A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
