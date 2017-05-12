package RackTables::Schema::Result::IPv4RS;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::IPv4RS

=cut

__PACKAGE__->table("IPv4RS");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 inservice

  data_type: 'enum'
  default_value: 'no'
  extra: {list => ["yes","no"]}
  is_nullable: 0

=head2 rsip

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 rsport

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 rspool_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
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
  "inservice",
  {
    data_type => "enum",
    default_value => "no",
    extra => { list => ["yes", "no"] },
    is_nullable => 0,
  },
  "rsip",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "rsport",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 1 },
  "rspool_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "rsconfig",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("pool-endpoint", ["rspool_id", "rsip", "rsport"]);

=head1 RELATIONS

=head2 rspool

Type: belongs_to

Related object: L<RackTables::Schema::Result::IPv4RSPool>

=cut

__PACKAGE__->belongs_to(
  "rspool",
  "RackTables::Schema::Result::IPv4RSPool",
  { id => "rspool_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BgaWrWeJqebTFq+5rbVuOg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
