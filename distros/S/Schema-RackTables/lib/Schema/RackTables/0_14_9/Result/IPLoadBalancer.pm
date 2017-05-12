use utf8;
package Schema::RackTables::0_14_9::Result::IPLoadBalancer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_14_9::Result::IPLoadBalancer

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

=head1 TABLE: C<IPLoadBalancer>

=cut

__PACKAGE__->table("IPLoadBalancer");

=head1 ACCESSORS

=head2 object_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 rspool_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 vs_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 vsconfig

  data_type: 'text'
  is_nullable: 1

=head2 rsconfig

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "object_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "rspool_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "vs_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "vsconfig",
  { data_type => "text", is_nullable => 1 },
  "rsconfig",
  { data_type => "text", is_nullable => 1 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<LB-VS>

=over 4

=item * L</object_id>

=item * L</vs_id>

=back

=cut

__PACKAGE__->add_unique_constraint("LB-VS", ["object_id", "vs_id"]);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:05:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nA/I/oo2jwodka3aOaRQoQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
