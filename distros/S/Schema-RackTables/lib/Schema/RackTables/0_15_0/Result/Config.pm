use utf8;
package Schema::RackTables::0_15_0::Result::Config;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_15_0::Result::Config

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

=head1 TABLE: C<Config>

=cut

__PACKAGE__->table("Config");

=head1 ACCESSORS

=head2 varname

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 varvalue

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 vartype

  data_type: 'enum'
  default_value: 'string'
  extra: {list => ["string","uint"]}
  is_nullable: 0

=head2 emptyok

  data_type: 'enum'
  default_value: 'no'
  extra: {list => ["yes","no"]}
  is_nullable: 0

=head2 is_hidden

  data_type: 'enum'
  default_value: 'yes'
  extra: {list => ["yes","no"]}
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "varname",
  { data_type => "char", is_nullable => 0, size => 32 },
  "varvalue",
  { data_type => "char", is_nullable => 0, size => 255 },
  "vartype",
  {
    data_type => "enum",
    default_value => "string",
    extra => { list => ["string", "uint"] },
    is_nullable => 0,
  },
  "emptyok",
  {
    data_type => "enum",
    default_value => "no",
    extra => { list => ["yes", "no"] },
    is_nullable => 0,
  },
  "is_hidden",
  {
    data_type => "enum",
    default_value => "yes",
    extra => { list => ["yes", "no"] },
    is_nullable => 0,
  },
  "description",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</varname>

=back

=cut

__PACKAGE__->set_primary_key("varname");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:05:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:W9uwiXf2DZc5ZdS9QYO3Vg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
