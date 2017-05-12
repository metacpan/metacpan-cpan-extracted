use utf8;
package Schema::RackTables::0_19_5::Result::UserConfig;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_19_5::Result::UserConfig

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

=head1 TABLE: C<UserConfig>

=cut

__PACKAGE__->table("UserConfig");

=head1 ACCESSORS

=head2 varname

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 varvalue

  data_type: 'text'
  is_nullable: 0

=head2 user

  data_type: 'char'
  is_nullable: 0
  size: 64

=cut

__PACKAGE__->add_columns(
  "varname",
  { data_type => "char", is_nullable => 0, size => 32 },
  "varvalue",
  { data_type => "text", is_nullable => 0 },
  "user",
  { data_type => "char", is_nullable => 0, size => 64 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<user_varname>

=over 4

=item * L</user>

=item * L</varname>

=back

=cut

__PACKAGE__->add_unique_constraint("user_varname", ["user", "varname"]);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:02:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:831rbmBlaeF30KWqe4/BsA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
