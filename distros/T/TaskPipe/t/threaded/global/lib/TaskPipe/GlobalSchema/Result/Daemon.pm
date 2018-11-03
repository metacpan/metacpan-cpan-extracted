use utf8;
package TaskPipe::GlobalSchema::Result::Daemon;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

TaskPipe::GlobalSchema::Result::Daemon

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

=head1 TABLE: C<daemon>

=cut

__PACKAGE__->table("daemon");

=head1 ACCESSORS

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 pid

  data_type: 'integer'
  is_nullable: 1

=head2 orig_cmd

  data_type: 'text'
  is_nullable: 1

=head2 created_dt

  data_type: 'datetime'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "pid",
  { data_type => "integer", is_nullable => 1 },
  "orig_cmd",
  { data_type => "text", is_nullable => 1 },
  "created_dt",
  { data_type => "datetime", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->set_primary_key("name");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-09-03 11:05:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CvJhVWKwTUnQ4aIYD9HCrw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
