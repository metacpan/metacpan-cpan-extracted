package RackTables::Schema::Result::IPv4LB;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::IPv4LB

=cut

__PACKAGE__->table("IPv4LB");

=head1 ACCESSORS

=head2 object_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 rspool_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 vs_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 prio

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 vsconfig

  data_type: 'text'
  is_nullable: 1

=head2 rsconfig

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "object_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "rspool_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "vs_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "prio",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "vsconfig",
  { data_type => "text", is_nullable => 1 },
  "rsconfig",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->add_unique_constraint("LB-VS", ["object_id", "vs_id"]);

=head1 RELATIONS

=head2 object

Type: belongs_to

Related object: L<RackTables::Schema::Result::RackObject>

=cut

__PACKAGE__->belongs_to(
  "object",
  "RackTables::Schema::Result::RackObject",
  { id => "object_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

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

=head2 v

Type: belongs_to

Related object: L<RackTables::Schema::Result::IPv4VS>

=cut

__PACKAGE__->belongs_to(
  "v",
  "RackTables::Schema::Result::IPv4VS",
  { id => "vs_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:w9ne9tNvNpp9rvsukcGOzA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
