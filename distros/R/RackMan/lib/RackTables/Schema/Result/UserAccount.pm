package RackTables::Schema::Result::UserAccount;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::UserAccount

=cut

__PACKAGE__->table("UserAccount");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 user_name

  data_type: 'char'
  default_value: (empty string)
  is_nullable: 0
  size: 64

=head2 user_password_hash

  data_type: 'char'
  is_nullable: 1
  size: 40

=head2 user_realname

  data_type: 'char'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "user_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "user_name",
  { data_type => "char", default_value => "", is_nullable => 0, size => 64 },
  "user_password_hash",
  { data_type => "char", is_nullable => 1, size => 40 },
  "user_realname",
  { data_type => "char", is_nullable => 1, size => 64 },
);
__PACKAGE__->set_primary_key("user_id");
__PACKAGE__->add_unique_constraint("user_name", ["user_name"]);

=head1 RELATIONS

=head2 user_configs

Type: has_many

Related object: L<RackTables::Schema::Result::UserConfig>

=cut

__PACKAGE__->has_many(
  "user_configs",
  "RackTables::Schema::Result::UserConfig",
  { "foreign.user" => "self.user_name" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pKScDv2cSmg+7zP6+DyAqA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
