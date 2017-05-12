use utf8;
package Schema::RackTables::0_14_10::Result::Attribute;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_14_10::Result::Attribute

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

=head1 TABLE: C<Attribute>

=cut

__PACKAGE__->table("Attribute");

=head1 ACCESSORS

=head2 attr_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 attr_type

  data_type: 'enum'
  extra: {list => ["string","uint","float","dict"]}
  is_nullable: 1

=head2 attr_name

  data_type: 'char'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "attr_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "attr_type",
  {
    data_type => "enum",
    extra => { list => ["string", "uint", "float", "dict"] },
    is_nullable => 1,
  },
  "attr_name",
  { data_type => "char", is_nullable => 1, size => 64 },
);

=head1 PRIMARY KEY

=over 4

=item * L</attr_id>

=back

=cut

__PACKAGE__->set_primary_key("attr_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<attr_name>

=over 4

=item * L</attr_name>

=back

=cut

__PACKAGE__->add_unique_constraint("attr_name", ["attr_name"]);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:05:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EBVedTICgOUJBr9tkI7HdA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
