use utf8;
package Schema::RackTables::0_20_8::Result::VLANDomain;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_8::Result::VLANDomain

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

=head1 TABLE: C<VLANDomain>

=cut

__PACKAGE__->table("VLANDomain");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 description

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
  "description",
  { data_type => "char", is_nullable => 1, size => 255 },
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

=head2 vlandescriptions

Type: has_many

Related object: L<Schema::RackTables::0_20_8::Result::VLANDescription>

=cut

__PACKAGE__->has_many(
  "vlandescriptions",
  "Schema::RackTables::0_20_8::Result::VLANDescription",
  { "foreign.domain_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vlanswitches

Type: has_many

Related object: L<Schema::RackTables::0_20_8::Result::VLANSwitch>

=cut

__PACKAGE__->has_many(
  "vlanswitches",
  "Schema::RackTables::0_20_8::Result::VLANSwitch",
  { "foreign.domain_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:r26xD9giMg4OGAqnLG6b0g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
