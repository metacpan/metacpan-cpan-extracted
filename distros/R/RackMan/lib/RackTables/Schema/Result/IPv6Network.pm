package RackTables::Schema::Result::IPv6Network;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::IPv6Network

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
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("ip", ["ip", "mask"]);

=head1 RELATIONS

=head2 vlanipv6s

Type: has_many

Related object: L<RackTables::Schema::Result::VLANIPv6>

=cut

__PACKAGE__->has_many(
  "vlanipv6s",
  "RackTables::Schema::Result::VLANIPv6",
  { "foreign.ipv6net_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fqxIMouDqRaLPqHSbjd16A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
