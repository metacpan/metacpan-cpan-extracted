package TestX::CatalystX::ExtensionB::Schema::Result::Book;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

TestX::CatalystX::ExtensionB::Schema::Result::Book

=cut

__PACKAGE__->table("book");

=head1 ACCESSORS

=head2 id

  data_type: INTEGER
  default_value: undef
  is_nullable: 1
  size: undef

=head2 title

  data_type: TEXT
  default_value: undef
  is_nullable: 1
  size: undef

=head2 rating

  data_type: INTEGER
  default_value: undef
  is_nullable: 1
  size: undef

=head2 created

  data_type: INTEGER
  default_value: undef
  is_nullable: 1
  size: undef

=head2 updated

  data_type: INTEGER
  default_value: undef
  is_nullable: 1
  size: undef

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "title",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "rating",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "created",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "updated",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 book_authors

Type: has_many

Related object: L<TestX::CatalystX::ExtensionB::Schema::Result::BookAuthor>

=cut

__PACKAGE__->has_many(
  "book_authors",
  "TestX::CatalystX::ExtensionB::Schema::Result::BookAuthor",
  { "foreign.book_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.05002 @ 2010-02-17 16:27:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:enqGmdv33Ni7uxKjN30zdQ


# You can replace this text with custom content, and it will be preserved on regeneration

# many_to_many():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of has_many() relationship this many_to_many() is shortcut for
#     3) Name of belongs_to() relationship in model class of has_many() above
#   You must already have the has_many() defined to use a many_to_many().
__PACKAGE__->many_to_many(authors => 'book_authors', 'author');


#
# Enable automatic date handling
#
__PACKAGE__->add_columns(
    "created",
    { data_type => 'datetime', set_on_create => 1 },
    "updated",
    { data_type => 'datetime', set_on_create => 1, set_on_update => 1 },
);


=head2 author_count

Return the number of authors for the current book

=cut

sub author_count {
    my ($self) = @_;

    # Use the 'many_to_many' relationship to fetch all of the authors for the current
    # and the 'count' method in DBIx::Class::ResultSet to get a SQL COUNT
    return $self->authors->count;
}


=head2 author_list

Return a comma-separated list of authors for the current book

=cut

sub author_list {
    my ($self) = @_;

    # Loop through all authors for the current book, calling all the 'full_name' 
    # Result Class method for each
    my @names;
    foreach my $author ($self->authors) {
        push(@names, $author->full_name);
    }

    return join(', ', @names);
}


=head2 delete_allowed_by

Can the specified user delete the current book?

=cut

sub delete_allowed_by {
    my ($self, $user) = @_;
    
    # Only allow delete if user has 'admin' role
    return $user->has_role('admin');
}


1;
