
package Palm::Progect::Record;


use base 'Palm::Progect::VersionDelegator';
use Carp;
use strict;

use CLASS;
use base qw(Class::Accessor);

sub Accessors {
    qw(
        description
        note
        type
        priority
        completed
        completed_actual
        completed_limit
        level
        has_next
        has_child
        has_prev
        is_opened
        has_todo
        date_due
        todo_link_data
    )
}

CLASS->mk_accessors(CLASS->Accessors);

my %Categories = ('Unfiled' => 0);  # name => id

# Class method to set all available category names at once,
# using the Palm::StdAppinfo format of a list of hashrefs
# in the form of:
#     { name => 'Some cat', id => 7, renamed => 'who cares' }
#
sub set_categories {
    my $class = shift;

    my @categories = @_;

    if (!@categories or $categories[0]{'name'} !~ /^\s*unfiled\s*$/i ) {
        unshift @categories, { 'name' => 'Unfiled' };
    }

    %Categories = ();

    # I don't know what the category ids are used
    # for, considering the 'category number'
    # associated with a pdb record refers to
    # the category's *position* within this array,
    # not its 'id'.

    for (my $id = 0; $id < @categories; $id++) {

        my $name  = $categories[$id]{'name'};

        next unless $id;   # Skip 'Unfiled'
        next unless $name; # Skip blank categories

        $Categories{$name} = $id;
    }

    # Add the 'Unfiled' category, which is
    # always zero.
    $Categories{'Unfiled'} = 0;
}

# Class method to get all available category names, in
# the order of their category ids
sub get_categories {
    my $class = shift;

    # Since the keys and values are both meant to be
    # unique, we can reverse the %Categories hash:

    my %categories_by_id = reverse %Categories;

    my @categories;
    for my $id (sort { $a <=> $b } keys %categories_by_id) {
        push @categories, {
            id      => $id,
            name    => $categories_by_id{$id},
            renamed => 0,
        };
    }

    return @categories if wantarray;
    return \@categories;
}

# object method accessor
sub category_name {
    my $self = shift;
    if (defined $_[0]) {
        my $category_name = $_[0];

        $self->{category_name} = $category_name;

        if (not exists $Categories{$category_name}) {
            # Put this category_name in the Class-global %Categories
            # hash, setting it's category_id to the max number
            # of categories that are already there, plus one
            $Categories{$category_name} = (scalar keys %Categories);
        }
    }
    if ($self->{category_name} and $self->{category_name} eq 'Unfiled') {
        return '';
    }
    else {
        return $self->{category_name};
    }
}

# In order to assign a category id to a record, the category
# must already exist; i.e. it must have been set via
# the class methods set_categories or add_categories

sub category_id {
    my $self        = shift;
    my $category_id = shift;

    if (defined $category_id) {


        # Since both keys and values of %Categories are unique,
        # we can reverse the hash...
        my %cat_lookup = reverse %Categories;

        # Internally, we only maintain the category_name
        # and we lookup the id if its requested.
        # So if someone sets the category id, we actually
        # look up the category_name for that id and store it instead

        if (exists $cat_lookup{$category_id}) {
            $self->{'category_name'} = $cat_lookup{$category_id};
        }
        else {
            croak "There is no category with the id #$category_id.  Before setting a record's category call Palm::Progect::Records->set_categories with the complete list of categories\n";
        }
    }

    my $cat_name = $self->{'category_name'} || 'Unfiled';
    return $Categories{$cat_name};
}

1;

__END__

=head1 NAME

Palm::Progect::Record - Individual Records of the Progect Database

=cut

=head1 SYNOPSIS

    for my $rec (@{ $progect->records }) {
        my $description = $rec->description;
        my $priority    = $rec->priority;
        my $category    = $rec->category_name;
        print "[$priority] {$category} $description\n";
    }

=head1 DESCRIPTION

Each L<Palm::Progect> object contains a list of records in its C<records> method.

Each record is a C<Palm::Progect::Record> object.

=head1 CLASS METHODS

=over 4

=item set_categories

Class method to set all available category names at once,
using the Palm::StdAppinfo format of a list of hashrefs
in the form of:

    { name => 'Some cat', id => 7, renamed => 'who cares' }

=item get_categories

Class method to get all available categories
using the Palm::StdAppinfo format of a list of hashrefs
in the form of:

    { name => 'Some cat', id => 7, renamed => 'who cares' }

=back

=head1 METHODS

=over 4

=item description

The text of the record

=item note

The note attached to the record, if any.  If the record does not have a
note, then this value will be false.

=item type

The type of the record

Type will be one of the six types of records:

=over 4

=item RECORD_TYPE_PROGRESS

=item RECORD_TYPE_NUMERIC

=item RECORD_TYPE_ACTION

=item RECORD_TYPE_INFO

=item RECORD_TYPE_EXTENDED

=item RECORD_TYPE_LINK

=back

These symbols are available from the C<Palm::Progect::Constants> module.

For instance:

    use Palm::Progect::Constants;

    if ($rec->type == RECORD_TYPE_ACTION) {
        print "The record is an action item!\n";
    }

=item priority

Priority of the item, 1 - 5, or 0, for B<No priority>.

=item completed

The value of this field depends on the type of the record.

For action items, completed is B<true> if the record has been completed,
C<false> otherwise.

For progress items, completed is the percent complete, a value from 0-100.

For numeric items (e.g. 5/20), completed reflects the percent complete
(see C<completed_actual> and C<completed_limit>, below).  Note that
setting the C<completed> method will not affect C<completed_actual> or
C<completed_limit>.

=item completed_actual

=item completed_limit

Numeric items indicate their 'completeness' with an arbitrary ratio:
Some value out of another value, for instance 5 out of 20, or 5/20,
where 5 is the C<completed_actual> and 20 is the C<completed_limit>.

=item level

The indent level of the record.

=item has_next

True if the record has another record following it, false otherwise.

=item has_child

True if the record contains another record, false otherwise.

=item has_prev

True if the record follows another record, false otherwise.

=item is_opened

True if the record is open, revealing the records it contains, false otherwise.

=item has_todo

True if the record links to a record in the todo database, false otherwise.

=item date_due

The due date of the record, in unix time format (i.e. seconds since the epoch).
If the record does not have a due date then this value will be false.

=item category_name

The name of the record's category, if any.  If you set C<category_name>
to the name of a category that doesn't yet exist, then that category will
be created.

=back

=head1 AUTHOR

Michael Graham E<lt>mag-perl@occamstoothbrush.comE<gt>

Copyright (C) 2002-2005 Michael Graham.  All rights reserved.
This program is free software.  You can use, modify,
and distribute it under the same terms as Perl itself.

The latest version of this module can be found on http://www.occamstoothbrush.com/perl/

=head1 SEE ALSO

progconv

L<Palm::PDB(3)>

http://progect.sourceforge.net/

=cut
