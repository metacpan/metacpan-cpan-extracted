use utf8;
package Schema::RackTables::0_19_7::Result::IPv6Address;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_19_7::Result::IPv6Address

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

=head1 TABLE: C<IPv6Address>

=cut

__PACKAGE__->table("IPv6Address");

=head1 ACCESSORS

=head2 ip

  data_type: 'binary'
  is_nullable: 0
  size: 16

=head2 name

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
  { data_type => "binary", is_nullable => 0, size => 16 },
  "name",
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


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:02:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dCOnvp5W7BIrp1D5Fy/McA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
