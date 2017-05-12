package RackTables::Schema::Result::IPv4VS;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::IPv4VS

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
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 ipv4_lbs

Type: has_many

Related object: L<RackTables::Schema::Result::IPv4LB>

=cut

__PACKAGE__->has_many(
  "ipv4_lbs",
  "RackTables::Schema::Result::IPv4LB",
  { "foreign.vs_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:i0+Ajpi0rAEq5Acw/jOQiA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
