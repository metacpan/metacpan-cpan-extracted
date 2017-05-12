package RackTables::Schema::Result::TagStorage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::TagStorage

=cut

__PACKAGE__->table("TagStorage");

=head1 ACCESSORS

=head2 entity_realm

  data_type: 'enum'
  default_value: 'object'
  extra: {list => ["file","ipv4net","ipv4vs","ipv4rspool","object","rack","user","ipv6net"]}
  is_nullable: 0

=head2 entity_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 tag_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "entity_realm",
  {
    data_type => "enum",
    default_value => "object",
    extra => {
      list => [
        "file",
        "ipv4net",
        "ipv4vs",
        "ipv4rspool",
        "object",
        "rack",
        "user",
        "ipv6net",
      ],
    },
    is_nullable => 0,
  },
  "entity_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "tag_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->add_unique_constraint("entity_tag", ["entity_realm", "entity_id", "tag_id"]);

=head1 RELATIONS

=head2 tag

Type: belongs_to

Related object: L<RackTables::Schema::Result::TagTree>

=cut

__PACKAGE__->belongs_to(
  "tag",
  "RackTables::Schema::Result::TagTree",
  { id => "tag_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XXYXiCmSNCsqc91pDumJEw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
