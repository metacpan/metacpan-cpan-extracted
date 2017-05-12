use utf8;
package Schema::RackTables::0_20_7::Result::RackThumbnail;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_7::Result::RackThumbnail

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

=head1 TABLE: C<RackThumbnail>

=cut

__PACKAGE__->table("RackThumbnail");

=head1 ACCESSORS

=head2 rack_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 thumb_data

  data_type: 'blob'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "rack_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "thumb_data",
  { data_type => "blob", is_nullable => 1 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<rack_id>

=over 4

=item * L</rack_id>

=back

=cut

__PACKAGE__->add_unique_constraint("rack_id", ["rack_id"]);

=head1 RELATIONS

=head2 rack

Type: belongs_to

Related object: L<Schema::RackTables::0_20_7::Result::Object>

=cut

__PACKAGE__->belongs_to(
  "rack",
  "Schema::RackTables::0_20_7::Result::Object",
  { id => "rack_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0rgo3D6vOR4MqJTdEPQekA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
