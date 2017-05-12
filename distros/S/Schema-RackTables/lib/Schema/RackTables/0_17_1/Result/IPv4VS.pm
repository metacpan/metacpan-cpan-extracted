use utf8;
package Schema::RackTables::0_17_1::Result::IPv4VS;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_17_1::Result::IPv4VS

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

=head1 TABLE: C<IPv4VS>

=cut

__PACKAGE__->table("IPv4VS");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 vip

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 vport

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 proto

  data_type: 'enum'
  default_value: 'TCP'
  extra: {list => ["TCP","UDP"]}
  is_nullable: 0

=head2 name

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 vsconfig

  data_type: 'text'
  is_nullable: 1

=head2 rsconfig

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "vip",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "vport",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 1 },
  "proto",
  {
    data_type => "enum",
    default_value => "TCP",
    extra => { list => ["TCP", "UDP"] },
    is_nullable => 0,
  },
  "name",
  { data_type => "char", is_nullable => 1, size => 255 },
  "vsconfig",
  { data_type => "text", is_nullable => 1 },
  "rsconfig",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:04:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jWw+0olO8RBgrIjFtgL7jw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
