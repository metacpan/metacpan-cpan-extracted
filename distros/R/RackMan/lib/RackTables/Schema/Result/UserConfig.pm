package RackTables::Schema::Result::UserConfig;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::UserConfig

=cut

__PACKAGE__->table("UserConfig");

=head1 ACCESSORS

=head2 varname

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 32

=head2 varvalue

  data_type: 'text'
  is_nullable: 0

=head2 user

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 64

=cut

__PACKAGE__->add_columns(
  "varname",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 32 },
  "varvalue",
  { data_type => "text", is_nullable => 0 },
  "user",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 64 },
);
__PACKAGE__->add_unique_constraint("user_varname", ["user", "varname"]);

=head1 RELATIONS

=head2 varname

Type: belongs_to

Related object: L<RackTables::Schema::Result::Config>

=cut

__PACKAGE__->belongs_to(
  "varname",
  "RackTables::Schema::Result::Config",
  { varname => "varname" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 user

Type: belongs_to

Related object: L<RackTables::Schema::Result::UserAccount>

=cut

__PACKAGE__->belongs_to(
  "user",
  "RackTables::Schema::Result::UserAccount",
  { user_name => "user" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:n2AP4dtY0ARmDPSozVLmDg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
