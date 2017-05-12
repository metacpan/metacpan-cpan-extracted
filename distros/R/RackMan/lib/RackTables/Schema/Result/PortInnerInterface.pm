package RackTables::Schema::Result::PortInnerInterface;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::PortInnerInterface

=cut

__PACKAGE__->table("PortInnerInterface");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 iif_name

  data_type: 'char'
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "iif_name",
  { data_type => "char", is_nullable => 0, size => 16 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("iif_name", ["iif_name"]);

=head1 RELATIONS

=head2 port_interface_compats

Type: has_many

Related object: L<RackTables::Schema::Result::PortInterfaceCompat>

=cut

__PACKAGE__->has_many(
  "port_interface_compats",
  "RackTables::Schema::Result::PortInterfaceCompat",
  { "foreign.iif_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/G/JroQ5fJyh4QzHJT/keA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
