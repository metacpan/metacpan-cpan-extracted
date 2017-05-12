package TestX::CatalystX::ExtensionB::Schema::Result::BookAuthor;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

TestX::CatalystX::ExtensionB::Schema::Result::BookAuthor

=cut

__PACKAGE__->table("book_author");

=head1 ACCESSORS

=head2 book_id

  data_type: INTEGER
  default_value: undef
  is_foreign_key: 1
  is_nullable: 1
  size: undef

=head2 author_id

  data_type: INTEGER
  default_value: undef
  is_foreign_key: 1
  is_nullable: 1
  size: undef

=cut

__PACKAGE__->add_columns(
  "book_id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => undef,
  },
  "author_id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("book_id", "author_id");

=head1 RELATIONS

=head2 book

Type: belongs_to

Related object: L<TestX::CatalystX::ExtensionB::Schema::Result::Book>

=cut

__PACKAGE__->belongs_to(
  "book",
  "TestX::CatalystX::ExtensionB::Schema::Result::Book",
  { id => "book_id" },
  { join_type => "LEFT" },
);

=head2 author

Type: belongs_to

Related object: L<TestX::CatalystX::ExtensionB::Schema::Result::Author>

=cut

__PACKAGE__->belongs_to(
  "author",
  "TestX::CatalystX::ExtensionB::Schema::Result::Author",
  { id => "author_id" },
  { join_type => "LEFT" },
);


# Created by DBIx::Class::Schema::Loader v0.05002 @ 2010-02-17 16:27:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZMK0hr6Xt1qblHTYLKo18g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
