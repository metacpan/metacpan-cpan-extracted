use utf8;
package Schema::RackTables::0_20_7::Result::IPv4Allocation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_7::Result::IPv4Allocation

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

=head1 TABLE: C<IPv4Allocation>

=cut

__PACKAGE__->table("IPv4Allocation");

=head1 ACCESSORS

=head2 object_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 ip

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 name

  data_type: 'char'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 type

  data_type: 'enum'
  default_value: 'regular'
  extra: {list => ["regular","shared","virtual","router","point2point"]}
  is_nullable: 0

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
  "ip",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "name",
  { data_type => "char", default_value => "", is_nullable => 0, size => 255 },
  "type",
  {
    data_type => "enum",
    default_value => "regular",
    extra => {
      list => ["regular", "shared", "virtual", "router", "point2point"],
    },
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</object_id>

=item * L</ip>

=back

=cut

__PACKAGE__->set_primary_key("object_id", "ip");

=head1 RELATIONS

=head2 object

Type: belongs_to

Related object: L<Schema::RackTables::0_20_7::Result::Object>

=cut

__PACKAGE__->belongs_to(
  "object",
  "Schema::RackTables::0_20_7::Result::Object",
  { id => "object_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CA2x21MePAury4jZ/tQXsw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
