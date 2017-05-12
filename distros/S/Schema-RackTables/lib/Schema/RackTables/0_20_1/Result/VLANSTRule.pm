use utf8;
package Schema::RackTables::0_20_1::Result::VLANSTRule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_1::Result::VLANSTRule

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

=head1 TABLE: C<VLANSTRule>

=cut

__PACKAGE__->table("VLANSTRule");

=head1 ACCESSORS

=head2 vst_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 rule_no

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 port_pcre

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 port_role

  data_type: 'enum'
  default_value: 'none'
  extra: {list => ["access","trunk","anymode","uplink","downlink","none"]}
  is_nullable: 0

=head2 wrt_vlans

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 description

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "vst_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "rule_no",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "port_pcre",
  { data_type => "char", is_nullable => 0, size => 255 },
  "port_role",
  {
    data_type => "enum",
    default_value => "none",
    extra => {
      list => ["access", "trunk", "anymode", "uplink", "downlink", "none"],
    },
    is_nullable => 0,
  },
  "wrt_vlans",
  { data_type => "char", is_nullable => 1, size => 255 },
  "description",
  { data_type => "char", is_nullable => 1, size => 255 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<vst-rule>

=over 4

=item * L</vst_id>

=item * L</rule_no>

=back

=cut

__PACKAGE__->add_unique_constraint("vst-rule", ["vst_id", "rule_no"]);

=head1 RELATIONS

=head2 vst

Type: belongs_to

Related object: L<Schema::RackTables::0_20_1::Result::VLANSwitchTemplate>

=cut

__PACKAGE__->belongs_to(
  "vst",
  "Schema::RackTables::0_20_1::Result::VLANSwitchTemplate",
  { id => "vst_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:c8GXf/fbAw2RgDGUTN1lGA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
