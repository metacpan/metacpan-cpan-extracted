package Perl::Structure::LinkedList;
use strict;
use warnings;
use Perl::Config;  # don't use Perl::Types inside itself, in order to avoid circular includes
our $VERSION = 0.001_000;

# [[[ INCLUDES ]]]
# NEED FIX: this is also a valid Perl Class, but we can't inherit from Perl::Class due to circular references?
use Perl::Structure::Array;

package Perl::Structure::LinkedListReference;
use parent qw(Perl::Type::Modifier::Reference);
use Perl::Type::Modifier::Reference;

# linked lists are comprised of nodes
use Perl::Structure::LinkedList::Node;

our hashref $properties =
{
	head => my Perl::Structure::LinkedList::NodeReference $TYPED_head = undef,  # start with head = undef so we can test for empty list
};

sub new_from_arrayref {
    { my Perl::Structure::LinkedListReference $RETURN_TYPE };
    (my string $class, my arrayref $input) = @ARG;
#	Perl::diag("in new_from_arrayref(), received \$class = '$class', and \$input =\n" . Dumper($input) . "\n");
	my unknown $output = $class->new();
	my integer $i;
	for ($i = (scalar(@{$input}) - 1); $i >= 0; $i--)
	{
		linkedlist_unshift($output, $input->[$i]);
	}
    return $output;
}

# do not name just "unshift" to avoid confusion with Perl builtin
sub linkedlist_unshift {
    { my void $RETURN_TYPE };
    (my Perl::Structure::LinkedListReference $list, my unknown $element) = @ARG; 
	my Perl::Structure::LinkedList::NodeReference $new_node = Perl::Structure::LinkedList::NodeReference->new();
	$new_node->{data} = $element;
	$new_node->{next} = $list->{head};
	$list->{head} = $new_node;
    return;
}

sub DUMPER { { my string $RETURN_TYPE };(my Perl::Structure::LinkedListReference $data) = @ARG; return $data->{head}->DUMPER(); }


# [[[ LINKED LISTS ]]]

# ref to linked list
# DEV NOTE: we only provide data structure references, not the direct data structures themselves,
# because an Perl::Class is a blessed hash _reference_, and we are not natively implementing the data structures in C here;
# thus the slightly weird naming convention where some places have delimeters (:: or _) and some don't,
# I favored the consistency of user-side RPerl data type short-form package alias _ delimeter over the Perl system-side package name scope :: delimeter 
package  # hide from PAUSE indexing
    linkedlistref;
use parent qw(Perl::Structure::LinkedListReference);
use Perl::Structure::LinkedList;
# TODO: check if these (and other) symbol copies can be shortened???   move integer import() subroutine to be automatically called by 'use' command?
our $properties = $properties; our $new_from_arrayref = $new_from_arrayref; our $linkedlist_unshift = $linkedlist_unshift; our $DUMPER = $DUMPER;

# [[[ INT LINKED LISTS ]]]

# (ref to linked list) of integers
package  # hide from PAUSE indexing
    linkedlistref::integer;
use parent qw(linkedlistref);

# NEED ADD: remaining sub-types

1;  # end of class
