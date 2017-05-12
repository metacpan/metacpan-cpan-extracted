package RackTables::Schema::Result::Script;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::Script

=cut

__PACKAGE__->table("Script");

=head1 ACCESSORS

=head2 script_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 script_text

  data_type: 'longtext'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "script_name",
  { data_type => "char", is_nullable => 0, size => 64 },
  "script_text",
  { data_type => "longtext", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("script_name");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:E0IIl7ESVebBLhpBxtyfFw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
