use utf8;
package Schema::RackTables::0_17_3::Result::Link;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_17_3::Result::Link

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

=head1 TABLE: C<Link>

=cut

__PACKAGE__->table("Link");

=head1 ACCESSORS

=head2 porta

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 portb

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "porta",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "portb",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</porta>

=item * L</portb>

=back

=cut

__PACKAGE__->set_primary_key("porta", "portb");

=head1 UNIQUE CONSTRAINTS

=head2 C<porta>

=over 4

=item * L</porta>

=back

=cut

__PACKAGE__->add_unique_constraint("porta", ["porta"]);

=head2 C<portb>

=over 4

=item * L</portb>

=back

=cut

__PACKAGE__->add_unique_constraint("portb", ["portb"]);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:04:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ue4E3oTXZmayojHGhuFZRA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
