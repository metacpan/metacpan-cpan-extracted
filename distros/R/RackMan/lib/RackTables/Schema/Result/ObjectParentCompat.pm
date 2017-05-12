package RackTables::Schema::Result::ObjectParentCompat;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::ObjectParentCompat

=cut

__PACKAGE__->table("ObjectParentCompat");

=head1 ACCESSORS

=head2 parent_objtype_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 child_objtype_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "parent_objtype_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "child_objtype_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->add_unique_constraint("parent_child", ["parent_objtype_id", "child_objtype_id"]);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+kuJmFHtZQvmcAvHDfQDtA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
