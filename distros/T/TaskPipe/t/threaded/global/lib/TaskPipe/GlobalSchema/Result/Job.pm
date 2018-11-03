use utf8;
package TaskPipe::GlobalSchema::Result::Job;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

TaskPipe::GlobalSchema::Result::Job

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

=head1 TABLE: C<job>

=cut

__PACKAGE__->table("job");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 project

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 pid

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 shell

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 orig_cmd

  data_type: 'text'
  is_nullable: 1

=head2 created_dt

  data_type: 'datetime'
  is_nullable: 1

=head2 conf

  data_type: 'mediumtext'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "project",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pid",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "shell",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "orig_cmd",
  { data_type => "text", is_nullable => 1 },
  "created_dt",
  { data_type => "datetime", is_nullable => 1 },
  "conf",
  { data_type => "mediumtext", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-09-03 11:05:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ScGKaEh9uVAsMRZWd46FHg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
