use utf8;
package Schema::RackTables::0_20_8::Result::VSPorts;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_8::Result::VSPorts

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

=head1 TABLE: C<VSPorts>

=cut

__PACKAGE__->table("VSPorts");

=head1 ACCESSORS

=head2 vs_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 proto

  data_type: 'enum'
  extra: {list => ["TCP","UDP","MARK"]}
  is_nullable: 0

=head2 vport

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 vsconfig

  data_type: 'text'
  is_nullable: 1

=head2 rsconfig

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "vs_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "proto",
  {
    data_type => "enum",
    extra => { list => ["TCP", "UDP", "MARK"] },
    is_nullable => 0,
  },
  "vport",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "vsconfig",
  { data_type => "text", is_nullable => 1 },
  "rsconfig",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</vs_id>

=item * L</proto>

=item * L</vport>

=back

=cut

__PACKAGE__->set_primary_key("vs_id", "proto", "vport");

=head1 RELATIONS

=head2 v

Type: belongs_to

Related object: L<Schema::RackTables::0_20_8::Result::VS>

=cut

__PACKAGE__->belongs_to(
  "v",
  "Schema::RackTables::0_20_8::Result::VS",
  { id => "vs_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);

=head2 vsenabled_ports

Type: has_many

Related object: L<Schema::RackTables::0_20_8::Result::VSEnabledPorts>

=cut

__PACKAGE__->has_many(
  "vsenabled_ports",
  "Schema::RackTables::0_20_8::Result::VSEnabledPorts",
  {
    "foreign.proto" => "self.proto",
    "foreign.vport" => "self.vport",
    "foreign.vs_id" => "self.vs_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WLQL1l3Ur6PAMAeXC5g++w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
