use utf8;
package Perl5::CoreSmokeDB::Schema::Result::FailureForEnv;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Perl5::CoreSmokeDB::Schema::Result::FailureForEnv

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

=head1 TABLE: C<failures_for_env>

=cut

__PACKAGE__->table("failures_for_env");

=head1 ACCESSORS

=head2 result_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 failure_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "result_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "failure_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<failures_for_env_result_id_failure_id_key>

=over 4

=item * L</result_id>

=item * L</failure_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "failures_for_env_result_id_failure_id_key",
  ["result_id", "failure_id"],
);

=head1 RELATIONS

=head2 failure

Type: belongs_to

Related object: L<Perl5::CoreSmokeDB::Schema::Result::Failure>

=cut

__PACKAGE__->belongs_to(
  "failure",
  "Perl5::CoreSmokeDB::Schema::Result::Failure",
  { id => "failure_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 result

Type: belongs_to

Related object: L<Perl5::CoreSmokeDB::Schema::Result::Result>

=cut

__PACKAGE__->belongs_to(
  "result",
  "Perl5::CoreSmokeDB::Schema::Result::Result",
  { id => "result_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2022-09-06 09:15:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:s/llMes/nmwNe5cYf1TFeA

=head2 $record->as_hashref

Returns a HashRef with the inflated columns.

=cut

sub as_hashref {
    my $self = shift;

    my $record = { $self->get_inflated_columns };

    return $record;
}

1;
