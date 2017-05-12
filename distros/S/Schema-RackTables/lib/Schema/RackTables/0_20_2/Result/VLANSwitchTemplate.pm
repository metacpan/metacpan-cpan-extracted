use utf8;
package Schema::RackTables::0_20_2::Result::VLANSwitchTemplate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_2::Result::VLANSwitchTemplate

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

=head1 TABLE: C<VLANSwitchTemplate>

=cut

__PACKAGE__->table("VLANSwitchTemplate");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 mutex_rev

  data_type: 'integer'
  is_nullable: 0

=head2 description

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 saved_by

  data_type: 'char'
  is_nullable: 0
  size: 64

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "mutex_rev",
  { data_type => "integer", is_nullable => 0 },
  "description",
  { data_type => "char", is_nullable => 1, size => 255 },
  "saved_by",
  { data_type => "char", is_nullable => 0, size => 64 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<description>

=over 4

=item * L</description>

=back

=cut

__PACKAGE__->add_unique_constraint("description", ["description"]);

=head1 RELATIONS

=head2 vlanstrules

Type: has_many

Related object: L<Schema::RackTables::0_20_2::Result::VLANSTRule>

=cut

__PACKAGE__->has_many(
  "vlanstrules",
  "Schema::RackTables::0_20_2::Result::VLANSTRule",
  { "foreign.vst_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vlanswitches

Type: has_many

Related object: L<Schema::RackTables::0_20_2::Result::VLANSwitch>

=cut

__PACKAGE__->has_many(
  "vlanswitches",
  "Schema::RackTables::0_20_2::Result::VLANSwitch",
  { "foreign.template_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Hw+9CT8rY3M6SBpnlPoeAA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
