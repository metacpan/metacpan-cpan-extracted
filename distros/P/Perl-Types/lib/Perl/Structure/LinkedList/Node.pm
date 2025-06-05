package Perl::Structure::LinkedList::Node;
use strict;
use warnings;
use Perl::Types;
our $VERSION = 0.001_100;

package Perl::Structure::LinkedList::NodeReference;
#use parent qw(Perl::Structure Perl::Type::Modifier::Reference);  # NEED UPGRADE, CORRELATION #rp023: Inline::CPP support for multiple inheritance
use parent qw(Perl::Type::Modifier::Reference);
#use Perl::Structure;
use Perl::Type::Modifier::Reference;

# must include here because we do not inherit data types
use Perl::Type::Integer;
use Perl::Type::String;
use Perl::Type::Unknown;
#use RPerl::CodeBlock::Subroutine::Method;  # NEED UPDATE, RPERL REFACTOR

our hashref $properties =
{
	data => my unknown $TYPED_data = undef,
	next => my Perl::Structure::LinkedList::NodeReference $TYPED_next = undef
};

sub DUMPER {
    { my string $RETURN_TYPE };
    (my Perl::Structure::LinkedList::NodeReference $node) = @ARG;
	my string $dumped = '[';
	my integer $is_first = 1;
	
	while (defined($node))
	{
		if ($is_first) { $is_first = 0; }
		else { $dumped .= ', '; }
		# TODO: handle non-scalartype linked list elements
		$dumped .= $node->{data};
		$node = $node->{next};
	}
	
	$dumped .= ']';
    return $dumped;
}

# ref to (linked list node)
# DEV NOTE: for naming conventions, see DEV NOTE in same code section of LinkedList.pm
package  # hide from PAUSE indexing
    linkedlistnoderef;
use parent qw(Perl::Structure::LinkedList::NodeReference);
use Perl::Structure::LinkedList::Node;
our $properties = $properties;

1;  # end of class
