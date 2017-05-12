use utf8;
package Schema::RackTables::0_14_4::Result::PortForwarding;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_14_4::Result::PortForwarding

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

=head1 TABLE: C<PortForwarding>

=cut

__PACKAGE__->table("PortForwarding");

=head1 ACCESSORS

=head2 object_id

  data_type: 'integer'
  is_nullable: 0

=head2 proto

  data_type: 'integer'
  is_nullable: 0

=head2 localip

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 localport

  data_type: 'integer'
  is_nullable: 0

=head2 remoteip

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 remoteport

  data_type: 'integer'
  is_nullable: 0

=head2 description

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "object_id",
  { data_type => "integer", is_nullable => 0 },
  "proto",
  { data_type => "integer", is_nullable => 0 },
  "localip",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "localport",
  { data_type => "integer", is_nullable => 0 },
  "remoteip",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "remoteport",
  { data_type => "integer", is_nullable => 0 },
  "description",
  { data_type => "char", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</object_id>

=item * L</proto>

=item * L</localip>

=item * L</localport>

=item * L</remoteip>

=item * L</remoteport>

=back

=cut

__PACKAGE__->set_primary_key(
  "object_id",
  "proto",
  "localip",
  "localport",
  "remoteip",
  "remoteport",
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:11:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:15S72Bx9tjEV3dnYsts8qw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
