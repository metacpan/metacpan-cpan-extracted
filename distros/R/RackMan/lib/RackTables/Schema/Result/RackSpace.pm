package RackTables::Schema::Result::RackSpace;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::RackSpace

=cut

__PACKAGE__->table("RackSpace");

=head1 ACCESSORS

=head2 rack_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 unit_no

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 atom

  data_type: 'enum'
  default_value: 'interior'
  extra: {list => ["front","interior","rear"]}
  is_nullable: 0

=head2 state

  data_type: 'enum'
  default_value: 'A'
  extra: {list => ["A","U","T","W"]}
  is_nullable: 0

=head2 object_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "rack_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "unit_no",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "atom",
  {
    data_type => "enum",
    default_value => "interior",
    extra => { list => ["front", "interior", "rear"] },
    is_nullable => 0,
  },
  "state",
  {
    data_type => "enum",
    default_value => "A",
    extra => { list => ["A", "U", "T", "W"] },
    is_nullable => 0,
  },
  "object_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("rack_id", "unit_no", "atom");

=head1 RELATIONS

=head2 rack

Type: belongs_to

Related object: L<RackTables::Schema::Result::Rack>

=cut

__PACKAGE__->belongs_to(
  "rack",
  "RackTables::Schema::Result::Rack",
  { id => "rack_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:B8qFZhzRw3OjGazgwU1/tw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
