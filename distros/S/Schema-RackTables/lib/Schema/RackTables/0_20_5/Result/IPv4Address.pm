use utf8;
package Schema::RackTables::0_20_5::Result::IPv4Address;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_5::Result::IPv4Address

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

=head1 TABLE: C<IPv4Address>

=cut

__PACKAGE__->table("IPv4Address");

=head1 ACCESSORS

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

=head2 comment

  data_type: 'char'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 reserved

  data_type: 'enum'
  extra: {list => ["yes","no"]}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "ip",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "name",
  { data_type => "char", default_value => "", is_nullable => 0, size => 255 },
  "comment",
  { data_type => "char", default_value => "", is_nullable => 0, size => 255 },
  "reserved",
  {
    data_type => "enum",
    extra => { list => ["yes", "no"] },
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</ip>

=back

=cut

__PACKAGE__->set_primary_key("ip");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:217TtwgGX17W3OxUxQms9g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
