use utf8;
package Schema::RackTables::0_20_2::Result::IPv6Network;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_2::Result::IPv6Network

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

=head1 TABLE: C<IPv6Network>

=cut

__PACKAGE__->table("IPv6Network");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 ip

  data_type: 'binary'
  is_nullable: 0
  size: 16

=head2 mask

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 last_ip

  data_type: 'binary'
  is_nullable: 0
  size: 16

=head2 name

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 comment

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
  "ip",
  { data_type => "binary", is_nullable => 0, size => 16 },
  "mask",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "last_ip",
  { data_type => "binary", is_nullable => 0, size => 16 },
  "name",
  { data_type => "char", is_nullable => 1, size => 255 },
  "comment",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<ip>

=over 4

=item * L</ip>

=item * L</mask>

=back

=cut

__PACKAGE__->add_unique_constraint("ip", ["ip", "mask"]);

=head1 RELATIONS

=head2 vlanipv6s

Type: has_many

Related object: L<Schema::RackTables::0_20_2::Result::VLANIPv6>

=cut

__PACKAGE__->has_many(
  "vlanipv6s",
  "Schema::RackTables::0_20_2::Result::VLANIPv6",
  { "foreign.ipv6net_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:F8JNI561nxw2gmkPs4IHdg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
