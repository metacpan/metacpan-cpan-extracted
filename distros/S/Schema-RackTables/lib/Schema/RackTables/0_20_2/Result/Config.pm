use utf8;
package Schema::RackTables::0_20_2::Result::Config;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_20_2::Result::Config

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

  data_type: 'text'
  is_nullable: 0

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

=head2 is_userdefined

  data_type: 'enum'
  default_value: 'no'
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
  { data_type => "text", is_nullable => 0 },
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
  "is_userdefined",
  {
    data_type => "enum",
    default_value => "no",
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

=head1 RELATIONS

=head2 user_configs

Type: has_many

Related object: L<Schema::RackTables::0_20_2::Result::UserConfig>

=cut

__PACKAGE__->has_many(
  "user_configs",
  "Schema::RackTables::0_20_2::Result::UserConfig",
  { "foreign.varname" => "self.varname" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:01:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dh7YW6cu4FHUFZszjkwSTg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
