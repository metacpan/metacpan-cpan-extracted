package RackTables::Schema::Result::LDAPCache;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::LDAPCache

=cut

__PACKAGE__->table("LDAPCache");

=head1 ACCESSORS

=head2 presented_username

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 successful_hash

  data_type: 'char'
  is_nullable: 0
  size: 40

=head2 first_success

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 last_retry

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 displayed_name

  data_type: 'char'
  is_nullable: 1
  size: 128

=head2 memberof

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "presented_username",
  { data_type => "char", is_nullable => 0, size => 64 },
  "successful_hash",
  { data_type => "char", is_nullable => 0, size => 40 },
  "first_success",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "last_retry",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "displayed_name",
  { data_type => "char", is_nullable => 1, size => 128 },
  "memberof",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->add_unique_constraint("presented_username", ["presented_username"]);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xK1AUjC9kK3VgRXfTbfjiw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
