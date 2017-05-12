use utf8;
package Schema::RackTables::0_20_9::Result::PortInnerInterface;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_9::Result::PortInnerInterface

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

=head1 TABLE: C<PortInnerInterface>

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

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<iif_name>

=over 4

=item * L</iif_name>

=back

=cut

__PACKAGE__->add_unique_constraint("iif_name", ["iif_name"]);

=head1 RELATIONS

=head2 port_interface_compats

Type: has_many

Related object: L<Schema::RackTables::0_20_9::Result::PortInterfaceCompat>

=cut

__PACKAGE__->has_many(
  "port_interface_compats",
  "Schema::RackTables::0_20_9::Result::PortInterfaceCompat",
  { "foreign.iif_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:REQc5VXj8z76r3lWSuM+QQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
