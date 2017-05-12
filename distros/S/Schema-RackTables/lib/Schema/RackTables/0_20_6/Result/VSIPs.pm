use utf8;
package Schema::RackTables::0_20_6::Result::VSIPs;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_6::Result::VSIPs

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

=head1 TABLE: C<VSIPs>

=cut

__PACKAGE__->table("VSIPs");

=head1 ACCESSORS

=head2 vs_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 vip

  data_type: 'varbinary'
  is_nullable: 0
  size: 16

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
  "vip",
  { data_type => "varbinary", is_nullable => 0, size => 16 },
  "vsconfig",
  { data_type => "text", is_nullable => 1 },
  "rsconfig",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</vs_id>

=item * L</vip>

=back

=cut

__PACKAGE__->set_primary_key("vs_id", "vip");

=head1 RELATIONS

=head2 v

Type: belongs_to

Related object: L<Schema::RackTables::0_20_6::Result::VS>

=cut

__PACKAGE__->belongs_to(
  "v",
  "Schema::RackTables::0_20_6::Result::VS",
  { id => "vs_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);

=head2 vsenabled_ips

Type: has_many

Related object: L<Schema::RackTables::0_20_6::Result::VSEnabledIPs>

=cut

__PACKAGE__->has_many(
  "vsenabled_ips",
  "Schema::RackTables::0_20_6::Result::VSEnabledIPs",
  { "foreign.vip" => "self.vip", "foreign.vs_id" => "self.vs_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PUTpzXlvvYWlgvJHzlhwEg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
