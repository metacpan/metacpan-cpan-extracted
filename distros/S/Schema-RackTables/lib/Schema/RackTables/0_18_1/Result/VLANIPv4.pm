use utf8;
package Schema::RackTables::0_18_1::Result::VLANIPv4;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_18_1::Result::VLANIPv4

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

=head1 TABLE: C<VLANIPv4>

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

=head1 UNIQUE CONSTRAINTS

=head2 C<network-domain>

=over 4

=item * L</ipv4net_id>

=item * L</domain_id>

=back

=cut

__PACKAGE__->add_unique_constraint("network-domain", ["ipv4net_id", "domain_id"]);

=head1 RELATIONS

=head2 ipv4net

Type: belongs_to

Related object: L<Schema::RackTables::0_18_1::Result::IPv4Network>

=cut

__PACKAGE__->belongs_to(
  "ipv4net",
  "Schema::RackTables::0_18_1::Result::IPv4Network",
  { id => "ipv4net_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);

=head2 vlandescription

Type: belongs_to

Related object: L<Schema::RackTables::0_18_1::Result::VLANDescription>

=cut

__PACKAGE__->belongs_to(
  "vlandescription",
  "Schema::RackTables::0_18_1::Result::VLANDescription",
  { domain_id => "domain_id", vlan_id => "vlan_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:03:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ssYZRMR8ElBZ/RUpDwTDZA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
