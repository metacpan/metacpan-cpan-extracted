use utf8;
package Statistics::Covid::Schema::Result::Datum;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Statistics::Covid::Schema::Result::Datum

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<Datum>

=cut

__PACKAGE__->table("Datum");

=head1 ACCESSORS

=head2 area

  data_type: 'real'
  default_value: 0
  is_nullable: 0

=head2 belongsto

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 confirmed

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 datasource

  data_type: 'varchar'
  default_value: '<NA>'
  is_nullable: 0
  size: 100

=head2 datetimeiso8601

  data_type: 'varchar'
  default_value: '<NA>'
  is_nullable: 0
  size: 21

=head2 datetimeunixepoch

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 id

  data_type: 'varchar'
  default_value: '<NA>'
  is_nullable: 0
  size: 100

=head2 name

  data_type: 'varchar'
  default_value: '<NA>'
  is_nullable: 0
  size: 100

=head2 population

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 recovered

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 terminal

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 type

  data_type: 'varchar'
  default_value: '<NA>'
  is_nullable: 0
  size: 100

=head2 unconfirmed

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "area",
  { data_type => "real", default_value => 0, is_nullable => 0 },
  "belongsto",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "confirmed",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "datasource",
  {
    data_type => "varchar",
    default_value => "<NA>",
    is_nullable => 0,
    size => 100,
  },
  "datetimeiso8601",
  {
    data_type => "varchar",
    default_value => "<NA>",
    is_nullable => 0,
    size => 21,
  },
  "datetimeunixepoch",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "id",
  {
    data_type => "varchar",
    default_value => "<NA>",
    is_nullable => 0,
    size => 100,
  },
  "name",
  {
    data_type => "varchar",
    default_value => "<NA>",
    is_nullable => 0,
    size => 100,
  },
  "population",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "recovered",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "terminal",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "type",
  {
    data_type => "varchar",
    default_value => "<NA>",
    is_nullable => 0,
    size => 100,
  },
  "unconfirmed",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=item * L</name>

=item * L</datetimeiso8601>

=back

=cut

__PACKAGE__->set_primary_key("id", "name", "datetimeiso8601");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-03-28 14:05:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OyulT9c8Ws7ICcWmGO47bw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
