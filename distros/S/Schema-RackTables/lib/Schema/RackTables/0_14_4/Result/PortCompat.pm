use utf8;
package Schema::RackTables::0_14_4::Result::PortCompat;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_14_4::Result::PortCompat

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

=head1 TABLE: C<PortCompat>

=cut

__PACKAGE__->table("PortCompat");

=head1 ACCESSORS

=head2 type1

  data_type: 'integer'
  is_nullable: 0

=head2 type2

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "type1",
  { data_type => "integer", is_nullable => 0 },
  "type2",
  { data_type => "integer", is_nullable => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:11:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:P1rXSOVF1EbXCm1TcQ2Y0w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
