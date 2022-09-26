use utf8;
package Perl5::CoreSmokeDB::Schema::Result::Failure;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Perl5::CoreSmokeDB::Schema::Result::Failure

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

=head1 TABLE: C<failure>

=cut

__PACKAGE__->table("failure");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'failure_id_seq'

=head2 test

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 status

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 extra

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "failure_id_seq",
  },
  "test",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "status",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "extra",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<failure_test_status_extra_key>

=over 4

=item * L</test>

=item * L</status>

=item * L</extra>

=back

=cut

__PACKAGE__->add_unique_constraint("failure_test_status_extra_key", ["test", "status", "extra"]);

=head1 RELATIONS

=head2 failures_for_env

Type: has_many

Related object: L<Perl5::CoreSmokeDB::Schema::Result::FailureForEnv>

=cut

__PACKAGE__->has_many(
  "failures_for_env",
  "Perl5::CoreSmokeDB::Schema::Result::FailureForEnv",
  { "foreign.failure_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2022-09-06 09:15:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:47DdjPyTSksgr5Z6Dw+HgA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
