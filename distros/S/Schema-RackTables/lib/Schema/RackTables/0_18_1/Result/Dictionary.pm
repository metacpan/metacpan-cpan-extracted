use utf8;
package Schema::RackTables::0_18_1::Result::Dictionary;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_18_1::Result::Dictionary

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

=head1 TABLE: C<Dictionary>

=cut

__PACKAGE__->table("Dictionary");

=head1 ACCESSORS

=head2 chapter_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 dict_key

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 dict_value

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "chapter_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "dict_key",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "dict_value",
  { data_type => "char", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</dict_key>

=back

=cut

__PACKAGE__->set_primary_key("dict_key");

=head1 UNIQUE CONSTRAINTS

=head2 C<chap_to_val>

=over 4

=item * L</chapter_id>

=item * L</dict_value>

=back

=cut

__PACKAGE__->add_unique_constraint("chap_to_val", ["chapter_id", "dict_value"]);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:03:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DM/XAwV10Akrn+NfGGFAtg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
