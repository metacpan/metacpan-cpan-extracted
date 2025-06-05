package Perl::Structure::Graph::Tree::Binary;
use strict;
use warnings;
use Perl::Config;  # don't use Perl::Types inside itself, in order to avoid circular includes
our $VERSION = 0.001_000;

# NEED FIX: weird inheritance for these as-reference-only data structures
package Perl::Structure::Graph::Tree::BinaryReference;
use parent qw(Perl::Structure::Graph::TreeReference);
use Perl::Structure::Graph::Tree;

# [[[ INCLUDES ]]]

# trees are comprised of nodes
use Perl::Structure::Graph::Tree::Binary::Node;

# coderef parameter accepted by traverse method(s)
use Perl::Structure::CodeReference;

# must include here because we do not inherit data types
use Perl::Type::Unknown;
use Perl::Type::String;
use Perl::Structure::Array;
#use RPerl::CodeBlock::Subroutine::Method;  # NEED ADD: explicit method declarations  # NEED UPDATE, RPERL REFACTOR

our hashref $properties =
{
	root => my Perl::Structure::Graph::Tree::Binary::NodeReference $TYPED_root = undef,  # start with root = undef so we can test for empty tree
};

sub new_from_nested_arrayrefs {
    { my Perl::Structure::Graph::Tree::BinaryReference $RETURN_TYPE };
    (my string $class, my arrayref $input) = @ARG;
#	Perl::diag("in ...Tree::BinaryReference::new_from_nested_arrayrefs(), received \$class = '$class', and \$input =\n" . Dumper($input) . "\n");
	my unknown $output = $class->new();

	$output->{root} = binarytreenoderef->new_from_nested_arrayrefs($input);
    return $output;
}

# much happens in the Node class, provide wrapper methods
sub traverse_breadthfirst_queue { { my unknown $RETURN_TYPE };(my Perl::Structure::Graph::Tree::BinaryReference $self, my Perl::Structure::CodeReference $callback) = @ARG; return $self->{root}->traverse_breadthfirst_queue($callback) if defined($self->{root}); }
sub traverse_depthfirst_preorder { { my unknown $RETURN_TYPE };(my Perl::Structure::Graph::Tree::BinaryReference $self, my Perl::Structure::CodeReference $callback) = @ARG; return $self->{root}->traverse_depthfirst_preorder($callback) if defined($self->{root}); }
sub to_nested_arrayrefs { { my arrayref $RETURN_TYPE };(my Perl::Structure::Graph::Tree::BinaryReference $data) = @ARG; return $data->{root}->to_nested_arrayrefs(); }


# [[[ BINARY TREES ]]]

# ref to binary tree
# DEV NOTE: for naming conventions, see DEV NOTE in same code section of LinkedList.pm
package  # hide from PAUSE indexing
    binarytreeref;
use parent qw(Perl::Structure::Graph::Tree::BinaryReference);
use Perl::Structure::Graph::Tree::Binary;
our $properties = $properties; our $new_from_nested_arrayrefs = $new_from_nested_arrayrefs; our $traverse_depthfirst_preorder = $traverse_depthfirst_preorder; our $to_nested_arrayrefs = $to_nested_arrayrefs; our $traverse_breadthfirst_queue = $traverse_breadthfirst_queue;

# [[[ INT BINARY TREES ]]]

# (ref to binary tree) of integers
package  # hide from PAUSE indexing
    integer_binarytreeref;
use parent qw(binarytreeref);
our $properties = $properties; our $new_from_arrayref = $new_from_arrayref; our $binarytree_unshift = $binarytree_unshift; our $DUMPER = $DUMPER;

# NEED ADD: remaining sub-types

1;  # end of class
