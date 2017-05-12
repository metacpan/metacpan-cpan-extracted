use utf8;
package Schema::RackTables::0_19_0::Result::Port;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_19_0::Result::Port

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<Port>

=cut

__PACKAGE__->table("Port");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 object_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'char'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 iif_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 type

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 l2address

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 reservation_comment

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 label

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "object_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "char", default_value => "", is_nullable => 0, size => 255 },
  "iif_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "type",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "l2address",
  { data_type => "char", is_nullable => 1, size => 64 },
  "reservation_comment",
  { data_type => "char", is_nullable => 1, size => 255 },
  "label",
  { data_type => "char", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<object_iif_oif_name>

=over 4

=item * L</object_id>

=item * L</iif_id>

=item * L</type>

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "object_iif_oif_name",
  ["object_id", "iif_id", "type", "name"],
);

=head1 RELATIONS

=head2 link_porta

Type: might_have

Related object: L<Schema::RackTables::0_19_0::Result::Link>

=cut

__PACKAGE__->might_have(
  "link_porta",
  "Schema::RackTables::0_19_0::Result::Link",
  { "foreign.porta" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 link_portb

Type: might_have

Related object: L<Schema::RackTables::0_19_0::Result::Link>

=cut

__PACKAGE__->might_have(
  "link_portb",
  "Schema::RackTables::0_19_0::Result::Link",
  { "foreign.portb" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 object

Type: belongs_to

Related object: L<Schema::RackTables::0_19_0::Result::RackObject>

=cut

__PACKAGE__->belongs_to(
  "object",
  "Schema::RackTables::0_19_0::Result::RackObject",
  { id => "object_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);

=head2 port_interface_compat

Type: belongs_to

Related object: L<Schema::RackTables::0_19_0::Result::PortInterfaceCompat>

=cut

__PACKAGE__->belongs_to(
  "port_interface_compat",
  "Schema::RackTables::0_19_0::Result::PortInterfaceCompat",
  { iif_id => "iif_id", oif_id => "type" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:03:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9sc5ySIFmCDjp1RZE2X2gQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
