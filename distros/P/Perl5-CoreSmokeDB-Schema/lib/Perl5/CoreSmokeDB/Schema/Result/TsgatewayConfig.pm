use utf8;
package Perl5::CoreSmokeDB::Schema::Result::TsgatewayConfig;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Perl5::CoreSmokeDB::Schema::Result::TsgatewayConfig

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

=head1 TABLE: C<tsgateway_config>

=cut

__PACKAGE__->table("tsgateway_config");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'tsgateway_config_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 value

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "tsgateway_config_id_seq",
  },
  "name",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "value",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<tsgateway_config_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("tsgateway_config_name_key", ["name"]);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2022-09-06 09:15:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OHrzHJomHrUylc1ROdEW4Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
