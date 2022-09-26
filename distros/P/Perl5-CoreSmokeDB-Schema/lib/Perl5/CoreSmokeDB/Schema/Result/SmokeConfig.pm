use utf8;
package Perl5::CoreSmokeDB::Schema::Result::SmokeConfig;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Perl5::CoreSmokeDB::Schema::Result::SmokeConfig

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

=head1 TABLE: C<smoke_config>

=cut

__PACKAGE__->table("smoke_config");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'smoke_config_id_seq'

=head2 md5

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 config

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
    sequence          => "smoke_config_id_seq",
  },
  "md5",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "config",
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

=head2 C<smoke_config_md5_key>

=over 4

=item * L</md5>

=back

=cut

__PACKAGE__->add_unique_constraint("smoke_config_md5_key", ["md5"]);

=head1 RELATIONS

=head2 reports

Type: has_many

Related object: L<Perl5::CoreSmokeDB::Schema::Result::Report>

=cut

__PACKAGE__->has_many(
  "reports",
  "Perl5::CoreSmokeDB::Schema::Result::Report",
  { "foreign.sconfig_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2022-09-06 09:15:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DEINsU6dlw5NyLK/K/pFaQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
