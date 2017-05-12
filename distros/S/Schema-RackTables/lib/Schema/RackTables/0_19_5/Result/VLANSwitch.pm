use utf8;
package Schema::RackTables::0_19_5::Result::VLANSwitch;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_19_5::Result::VLANSwitch

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

=head1 TABLE: C<VLANSwitch>

=cut

__PACKAGE__->table("VLANSwitch");

=head1 ACCESSORS

=head2 object_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 domain_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 template_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 mutex_rev

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 out_of_sync

  data_type: 'enum'
  default_value: 'yes'
  extra: {list => ["yes","no"]}
  is_nullable: 0

=head2 last_errno

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 last_change

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 last_push_started

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 last_push_finished

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 last_error_ts

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "object_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "domain_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "template_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "mutex_rev",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "out_of_sync",
  {
    data_type => "enum",
    default_value => "yes",
    extra => { list => ["yes", "no"] },
    is_nullable => 0,
  },
  "last_errno",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "last_change",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "last_push_started",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "last_push_finished",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "last_error_ts",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<object_id>

=over 4

=item * L</object_id>

=back

=cut

__PACKAGE__->add_unique_constraint("object_id", ["object_id"]);

=head1 RELATIONS

=head2 domain

Type: belongs_to

Related object: L<Schema::RackTables::0_19_5::Result::VLANDomain>

=cut

__PACKAGE__->belongs_to(
  "domain",
  "Schema::RackTables::0_19_5::Result::VLANDomain",
  { id => "domain_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 object

Type: belongs_to

Related object: L<Schema::RackTables::0_19_5::Result::RackObject>

=cut

__PACKAGE__->belongs_to(
  "object",
  "Schema::RackTables::0_19_5::Result::RackObject",
  { id => "object_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 template

Type: belongs_to

Related object: L<Schema::RackTables::0_19_5::Result::VLANSwitchTemplate>

=cut

__PACKAGE__->belongs_to(
  "template",
  "Schema::RackTables::0_19_5::Result::VLANSwitchTemplate",
  { id => "template_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:02:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qhg1pYJBTSLhKQpznwFqcA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
