package RackTables::Schema::Result::PortInterfaceCompat;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::PortInterfaceCompat

=cut

__PACKAGE__->table("PortInterfaceCompat");

=head1 ACCESSORS

=head2 iif_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 oif_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "iif_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "oif_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->add_unique_constraint("pair", ["iif_id", "oif_id"]);

=head1 RELATIONS

=head2 ports

Type: has_many

Related object: L<RackTables::Schema::Result::Port>

=cut

__PACKAGE__->has_many(
  "ports",
  "RackTables::Schema::Result::Port",
  { "foreign.iif_id" => "self.iif_id", "foreign.type" => "self.oif_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 iif

Type: belongs_to

Related object: L<RackTables::Schema::Result::PortInnerInterface>

=cut

__PACKAGE__->belongs_to(
  "iif",
  "RackTables::Schema::Result::PortInnerInterface",
  { id => "iif_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BmlJJmGN8QShoNQlPRiruw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
