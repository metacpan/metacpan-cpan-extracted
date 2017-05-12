package RackTables::Schema::Result::Atom;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::Atom

=cut

__PACKAGE__->table("Atom");

=head1 ACCESSORS

=head2 molecule_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 rack_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 unit_no

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 atom

  data_type: 'enum'
  extra: {list => ["front","interior","rear"]}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "molecule_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "rack_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "unit_no",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "atom",
  {
    data_type => "enum",
    extra => { list => ["front", "interior", "rear"] },
    is_nullable => 1,
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum://1etkrZSyj+Wzp7Xqzs2Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
