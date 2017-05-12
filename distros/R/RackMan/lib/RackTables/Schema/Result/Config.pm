package RackTables::Schema::Result::Config;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::Config

=cut

__PACKAGE__->table("Config");

=head1 ACCESSORS

=head2 varname

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 varvalue

  data_type: 'text'
  is_nullable: 0

=head2 vartype

  data_type: 'enum'
  default_value: 'string'
  extra: {list => ["string","uint"]}
  is_nullable: 0

=head2 emptyok

  data_type: 'enum'
  default_value: 'no'
  extra: {list => ["yes","no"]}
  is_nullable: 0

=head2 is_hidden

  data_type: 'enum'
  default_value: 'yes'
  extra: {list => ["yes","no"]}
  is_nullable: 0

=head2 is_userdefined

  data_type: 'enum'
  default_value: 'no'
  extra: {list => ["yes","no"]}
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "varname",
  { data_type => "char", is_nullable => 0, size => 32 },
  "varvalue",
  { data_type => "text", is_nullable => 0 },
  "vartype",
  {
    data_type => "enum",
    default_value => "string",
    extra => { list => ["string", "uint"] },
    is_nullable => 0,
  },
  "emptyok",
  {
    data_type => "enum",
    default_value => "no",
    extra => { list => ["yes", "no"] },
    is_nullable => 0,
  },
  "is_hidden",
  {
    data_type => "enum",
    default_value => "yes",
    extra => { list => ["yes", "no"] },
    is_nullable => 0,
  },
  "is_userdefined",
  {
    data_type => "enum",
    default_value => "no",
    extra => { list => ["yes", "no"] },
    is_nullable => 0,
  },
  "description",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("varname");

=head1 RELATIONS

=head2 user_configs

Type: has_many

Related object: L<RackTables::Schema::Result::UserConfig>

=cut

__PACKAGE__->has_many(
  "user_configs",
  "RackTables::Schema::Result::UserConfig",
  { "foreign.varname" => "self.varname" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fsDRhxqsxDgV9t7B4C9Y/A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
