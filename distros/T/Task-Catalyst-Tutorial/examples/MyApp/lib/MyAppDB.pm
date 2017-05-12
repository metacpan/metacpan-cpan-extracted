package MyAppDB;

=head1 NAME 

MyAppDB -- DBIC Schema Class

=cut

# Our schema needs to inherit from 'DBIx::Class::Schema'
use base qw/DBIx::Class::Schema/;

# Need to load the DB Model classes here.
# You can use this syntax if you want:
#    __PACKAGE__->load_classes(qw/Book BookAuthor Author User UserRole Role/);
# Also, if you simply want to load all of the classes in a directory
# of the same name as your schema class (as we do here) you can use:
#    __PACKAGE__->load_classes(qw//);
# But the variation below is more flexible in that it can be used to 
# load from multiple namespaces.
__PACKAGE__->load_classes({
    MyAppDB => [qw/Book BookAuthor Author User UserRole Role/]
});

1;
