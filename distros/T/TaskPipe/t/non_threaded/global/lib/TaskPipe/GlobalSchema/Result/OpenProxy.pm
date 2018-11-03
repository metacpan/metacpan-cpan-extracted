use utf8;
package TaskPipe::GlobalSchema::Result::OpenProxy;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

TaskPipe::GlobalSchema::Result::OpenProxy

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

=head1 TABLE: C<open_proxy>

=cut

__PACKAGE__->table("open_proxy");

=head1 ACCESSORS

=head2 ip

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 port

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 list_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 status

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 job_id

  data_type: 'bigint'
  is_nullable: 1

=head2 thread_id

  data_type: 'bigint'
  is_nullable: 1

=head2 checked_dt

  data_type: 'datetime'
  is_nullable: 1

=head2 last_used_dt

  data_type: 'datetime'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "ip",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "port",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "list_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "job_id",
  { data_type => "bigint", is_nullable => 1 },
  "thread_id",
  { data_type => "bigint", is_nullable => 1 },
  "checked_dt",
  { data_type => "datetime", is_nullable => 1 },
  "last_used_dt",
  { data_type => "datetime", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</ip>

=item * L</port>

=back

=cut

__PACKAGE__->set_primary_key("ip", "port");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-28 15:24:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QQ4t0rTGjLSqcQ7qNDG9Mg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
