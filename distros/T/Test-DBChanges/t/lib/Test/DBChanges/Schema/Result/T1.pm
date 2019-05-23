use utf8;
package Test::DBChanges::Schema::Result::T1;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Test::DBChanges::Schema::Result::T1

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<t1>

=cut

__PACKAGE__->table("t1");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 't1_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "t1_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 t2s

Type: has_many

Related object: L<Test::DBChanges::Schema::Result::T2>

=cut

__PACKAGE__->has_many(
  "t2s",
  "Test::DBChanges::Schema::Result::T2",
  { "foreign.name_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2018-12-19 10:07:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:52FgloW5X1V5sqF23VW4iA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
