use utf8;
package Schema::RackTables::0_14_7::Result::UserPermission;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_14_7::Result::UserPermission

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<UserPermission>

=cut

__PACKAGE__->table("UserPermission");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 page

  data_type: 'char'
  default_value: '%'
  is_nullable: 0
  size: 64

=head2 tab

  data_type: 'char'
  default_value: '%'
  is_nullable: 0
  size: 64

=head2 access

  data_type: 'enum'
  default_value: 'no'
  extra: {list => ["yes","no"]}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "page",
  { data_type => "char", default_value => "%", is_nullable => 0, size => 64 },
  "tab",
  { data_type => "char", default_value => "%", is_nullable => 0, size => 64 },
  "access",
  {
    data_type => "enum",
    default_value => "no",
    extra => { list => ["yes", "no"] },
    is_nullable => 0,
  },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<user_id>

=over 4

=item * L</user_id>

=item * L</page>

=item * L</tab>

=back

=cut

__PACKAGE__->add_unique_constraint("user_id", ["user_id", "page", "tab"]);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:05:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:M+9LlW9s7b1QjiPll8HVnA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
