package RackTables::Schema::Result::ServiceStorage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::ServiceStorage

=cut

__PACKAGE__->table("ServiceStorage");

=head1 ACCESSORS

=head2 entity_realm

  data_type: 'enum'
  default_value: 'object'
  extra: {list => ["file","ipv4net","ipv4vs","ipv4rspool","object","rack","user"]}
  is_nullable: 0

=head2 entity_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 service_id

  data_type: 'integer'
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
      ],
    },
    is_nullable => 0,
  },
  "entity_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "service_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->add_unique_constraint("entity_service", ["entity_realm", "entity_id", "service_id"]);

=head1 RELATIONS

=head2 service

Type: belongs_to

Related object: L<RackTables::Schema::Result::ServiceTree>

=cut

__PACKAGE__->belongs_to(
  "service",
  "RackTables::Schema::Result::ServiceTree",
  { id => "service_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MFSf6BdVJI7T2wEbIsBqGQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
