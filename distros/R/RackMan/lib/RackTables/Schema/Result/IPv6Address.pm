package RackTables::Schema::Result::IPv6Address;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::IPv6Address

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
__PACKAGE__->set_primary_key("ip");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oVwn1KM2aZgczdhVb6T9og


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
