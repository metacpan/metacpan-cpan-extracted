package RackTables::Schema::Result::FileLink;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::FileLink

=cut

__PACKAGE__->table("FileLink");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 file_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 entity_type

  data_type: 'enum'
  default_value: 'object'
  extra: {list => ["ipv4net","ipv4rspool","ipv4vs","object","rack","user","ipv6net"]}
  is_nullable: 0

=head2 entity_id

  data_type: 'integer'
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
  "file_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "entity_type",
  {
    data_type => "enum",
    default_value => "object",
    extra => {
      list => [
        "ipv4net",
        "ipv4rspool",
        "ipv4vs",
        "object",
        "rack",
        "user",
        "ipv6net",
      ],
    },
    is_nullable => 0,
  },
  "entity_id",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("FileLink-unique", ["file_id", "entity_type", "entity_id"]);

=head1 RELATIONS

=head2 file

Type: belongs_to

Related object: L<RackTables::Schema::Result::File>

=cut

__PACKAGE__->belongs_to(
  "file",
  "RackTables::Schema::Result::File",
  { id => "file_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kTzazKavCMOag9oebgN8Zw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
