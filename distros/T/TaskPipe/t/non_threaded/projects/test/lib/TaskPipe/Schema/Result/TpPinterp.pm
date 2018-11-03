use utf8;
package TaskPipe::Schema::Result::TpPinterp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

TaskPipe::Schema::Result::TpPinterp

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

=head1 TABLE: C<tp_pinterp>

=cut

__PACKAGE__->table("tp_pinterp");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 task_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 pinterp_md5

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 pinterp_dd

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "task_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pinterp_md5",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pinterp_dd",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-28 19:18:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QTARob0Lei7S2qX3gFzQOA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
