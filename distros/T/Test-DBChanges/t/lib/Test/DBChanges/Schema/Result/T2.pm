use utf8;
package Test::DBChanges::Schema::Result::T2;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Test::DBChanges::Schema::Result::T2

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<t2>

=cut

__PACKAGE__->table("t2");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 't2_id_seq'

=head2 name_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 value

  data_type: 'numeric'
  default_value: 1.234
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "t2_id_seq",
  },
  "name_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "value",
  { data_type => "numeric", default_value => 1.234, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 name

Type: belongs_to

Related object: L<Test::DBChanges::Schema::Result::T1>

=cut

__PACKAGE__->belongs_to(
  "name",
  "Test::DBChanges::Schema::Result::T1",
  { id => "name_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2018-12-19 10:07:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+NyG71+aiQeM/ZSdaOl8cg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
