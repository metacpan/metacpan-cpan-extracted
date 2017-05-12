use utf8;
package Schema::RackTables::0_16_1::Result::TagStorage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::RackTables::0_16_1::Result::TagStorage

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

=head1 TABLE: C<TagStorage>

=cut

__PACKAGE__->table("TagStorage");

=head1 ACCESSORS

=head2 target_realm

  data_type: 'enum'
  default_value: 'object'
  extra: {list => ["object","ipv4net","rack","ipv4vs","ipv4rspool","user"]}
  is_nullable: 0

=head2 target_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 tag_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "target_realm",
  {
    data_type => "enum",
    default_value => "object",
    extra => {
      list => ["object", "ipv4net", "rack", "ipv4vs", "ipv4rspool", "user"],
    },
    is_nullable => 0,
  },
  "target_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "tag_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<entity_tag>

=over 4

=item * L</target_realm>

=item * L</target_id>

=item * L</tag_id>

=back

=cut

__PACKAGE__->add_unique_constraint("entity_tag", ["target_realm", "target_id", "tag_id"]);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-22 23:04:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TBL/bqufYUWZDLi/1W5Yzw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
