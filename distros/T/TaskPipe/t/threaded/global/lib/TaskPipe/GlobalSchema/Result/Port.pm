use utf8;
package TaskPipe::GlobalSchema::Result::Port;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

TaskPipe::GlobalSchema::Result::Port

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

=head1 TABLE: C<port>

=cut

__PACKAGE__->table("port");

=head1 ACCESSORS

=head2 port

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 thread_id

  data_type: 'bigint'
  is_nullable: 1

=head2 job_id

  data_type: 'bigint'
  is_nullable: 1

=head2 process_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "port",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "thread_id",
  { data_type => "bigint", is_nullable => 1 },
  "job_id",
  { data_type => "bigint", is_nullable => 1 },
  "process_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</port>

=back

=cut

__PACKAGE__->set_primary_key("port");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-09-03 11:05:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KUuxZUcpSRarWUc76siiVA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
