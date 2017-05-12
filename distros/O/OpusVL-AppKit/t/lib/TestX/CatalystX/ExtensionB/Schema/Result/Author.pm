package TestX::CatalystX::ExtensionB::Schema::Result::Author;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");
__PACKAGE__->table("author");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "first_name",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "last_name",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many
(
  "book_authors",
  "TestX::CatalystX::ExtensionB::Schema::Result::BookAuthor",
  { "foreign.author_id" => "self.id" },
);


sub full_name 
{
    my ($self) = @_;
    return $self->first_name . ' ' . $self->last_name;
}

1;
