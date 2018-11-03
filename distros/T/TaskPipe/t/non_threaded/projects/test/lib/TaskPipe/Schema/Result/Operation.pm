use utf8;
package TaskPipe::Schema::Result::Operation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

TaskPipe::Schema::Result::Operation

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

=head1 TABLE: C<operations>

=cut

__PACKAGE__->table("operations");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 thread_data

  data_type: 'mediumtext'
  is_nullable: 1

=head2 thread_id

  data_type: 'integer'
  is_nullable: 1

=head2 target_table

  data_type: 'varchar'
  is_nullable: 1
  size: 190

=head2 result

  data_type: 'mediumtext'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "thread_data",
  { data_type => "mediumtext", is_nullable => 1 },
  "thread_id",
  { data_type => "integer", is_nullable => 1 },
  "target_table",
  { data_type => "varchar", is_nullable => 1, size => 190 },
  "result",
  { data_type => "mediumtext", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-28 19:18:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yNfX97hxDVIwufOK5LP3OQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
