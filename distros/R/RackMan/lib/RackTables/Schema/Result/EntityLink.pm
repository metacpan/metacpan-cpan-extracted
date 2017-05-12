package RackTables::Schema::Result::EntityLink;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::EntityLink

=cut

__PACKAGE__->table("EntityLink");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 parent_entity_type

  data_type: 'enum'
  extra: {list => ["ipv4net","ipv4rspool","ipv4vs","ipv6net","object","rack","user"]}
  is_nullable: 0

=head2 parent_entity_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 child_entity_type

  data_type: 'enum'
  extra: {list => ["file","object"]}
  is_nullable: 0

=head2 child_entity_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "parent_entity_type",
  {
    data_type => "enum",
    extra => {
      list => [
        "ipv4net",
        "ipv4rspool",
        "ipv4vs",
        "ipv6net",
        "object",
        "rack",
        "user",
      ],
    },
    is_nullable => 0,
  },
  "parent_entity_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "child_entity_type",
  {
    data_type => "enum",
    extra => { list => ["file", "object"] },
    is_nullable => 0,
  },
  "child_entity_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint(
  "EntityLink-unique",
  [
    "parent_entity_type",
    "parent_entity_id",
    "child_entity_type",
    "child_entity_id",
  ],
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ATYOD30L0SEcsfWclmHk5Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
