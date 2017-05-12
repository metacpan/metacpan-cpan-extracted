package RackTables::Schema::Result::Link;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::Link

=cut

__PACKAGE__->table("Link");

=head1 ACCESSORS

=head2 porta

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 portb

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 cable

  data_type: 'char'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "porta",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "portb",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "cable",
  { data_type => "char", is_nullable => 1, size => 64 },
);
__PACKAGE__->set_primary_key("porta", "portb");
__PACKAGE__->add_unique_constraint("portb", ["portb"]);
__PACKAGE__->add_unique_constraint("porta", ["porta"]);

=head1 RELATIONS

=head2 porta

Type: belongs_to

Related object: L<RackTables::Schema::Result::Port>

=cut

__PACKAGE__->belongs_to(
  "porta",
  "RackTables::Schema::Result::Port",
  { id => "porta" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 portb

Type: belongs_to

Related object: L<RackTables::Schema::Result::Port>

=cut

__PACKAGE__->belongs_to(
  "portb",
  "RackTables::Schema::Result::Port",
  { id => "portb" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7dE/VfVu3FXYKaho09Yyqw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
