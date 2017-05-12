use utf8;
package Schema::RackTables::0_16_2::Result::Chapter;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_16_2::Result::Chapter

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

=head1 TABLE: C<Chapter>

=cut

__PACKAGE__->table("Chapter");

=head1 ACCESSORS

=head2 chapter_no

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 sticky

  data_type: 'enum'
  default_value: 'no'
  extra: {list => ["yes","no"]}
  is_nullable: 1

=head2 chapter_name

  data_type: 'char'
  is_nullable: 0
  size: 128

=cut

__PACKAGE__->add_columns(
  "chapter_no",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "sticky",
  {
    data_type => "enum",
    default_value => "no",
    extra => { list => ["yes", "no"] },
    is_nullable => 1,
  },
  "chapter_name",
  { data_type => "char", is_nullable => 0, size => 128 },
);

=head1 PRIMARY KEY

=over 4

=item * L</chapter_no>

=back

=cut

__PACKAGE__->set_primary_key("chapter_no");

=head1 UNIQUE CONSTRAINTS

=head2 C<chapter_name>

=over 4

=item * L</chapter_name>

=back

=cut

__PACKAGE__->add_unique_constraint("chapter_name", ["chapter_name"]);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:04:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/oQ3juBTywHgyHrSfwhONg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
