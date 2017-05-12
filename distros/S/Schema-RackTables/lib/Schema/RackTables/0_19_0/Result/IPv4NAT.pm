use utf8;
package Schema::RackTables::0_19_0::Result::IPv4NAT;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_19_0::Result::IPv4NAT

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

=head1 TABLE: C<IPv4NAT>

=cut

__PACKAGE__->table("IPv4NAT");

=head1 ACCESSORS

=head2 object_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 proto

  data_type: 'enum'
  default_value: 'TCP'
  extra: {list => ["TCP","UDP"]}
  is_nullable: 0

=head2 localip

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 localport

  data_type: 'smallint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 remoteip

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 remoteport

  data_type: 'smallint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 description

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "object_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "proto",
  {
    data_type => "enum",
    default_value => "TCP",
    extra => { list => ["TCP", "UDP"] },
    is_nullable => 0,
  },
  "localip",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "localport",
  {
    data_type => "smallint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "remoteip",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "remoteport",
  {
    data_type => "smallint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "description",
  { data_type => "char", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</object_id>

=item * L</proto>

=item * L</localip>

=item * L</localport>

=item * L</remoteip>

=item * L</remoteport>

=back

=cut

__PACKAGE__->set_primary_key(
  "object_id",
  "proto",
  "localip",
  "localport",
  "remoteip",
  "remoteport",
);

=head1 RELATIONS

=head2 object

Type: belongs_to

Related object: L<Schema::RackTables::0_19_0::Result::RackObject>

=cut

__PACKAGE__->belongs_to(
  "object",
  "Schema::RackTables::0_19_0::Result::RackObject",
  { id => "object_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:03:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rFrg7aIadHVebyVBslLsXA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
