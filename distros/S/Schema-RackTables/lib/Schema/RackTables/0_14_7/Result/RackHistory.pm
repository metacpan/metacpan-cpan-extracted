use utf8;
package Schema::RackTables::0_14_7::Result::RackHistory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_14_7::Result::RackHistory

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

=head1 TABLE: C<RackHistory>

=cut

__PACKAGE__->table("RackHistory");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 name

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 deleted

  data_type: 'enum'
  extra: {list => ["yes","no"]}
  is_nullable: 1

=head2 row_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 height

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 ctime

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 user_name

  data_type: 'char'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "name",
  { data_type => "char", is_nullable => 1, size => 255 },
  "deleted",
  {
    data_type => "enum",
    extra => { list => ["yes", "no"] },
    is_nullable => 1,
  },
  "row_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "height",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "ctime",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "user_name",
  { data_type => "char", is_nullable => 1, size => 64 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:05:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Gxct0XEXrb1sHRw2WKy7KA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
