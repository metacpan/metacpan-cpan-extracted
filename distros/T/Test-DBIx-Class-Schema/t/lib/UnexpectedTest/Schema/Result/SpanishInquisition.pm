package UnexpectedTest::Schema::Result::SpanishInquisition;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

UnexpectedTest::Schema::Result::SpanishInquisition

=cut

__PACKAGE__->table("spanish_inquisition");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-09-04 20:46:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YkofcPvibqtk3EV5XLvXCg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
