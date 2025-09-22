#!/usr/bin/env perl
# NEED FIX, OUTDATED
# NEED FIX, OUTDATED
# NEED FIX, OUTDATED
use strict;
use warnings;
use Perl::Types;

# supported algorithms
#use Perl::Types::Algorithm::Graph::Tree::FOOBAZ;

# <<<=== TREE 1 ===>>>
# <<<=== TREE 1 ===>>>
# <<<=== TREE 1 ===>>>

my $nested_arrayrefs_chars = ['F', [['B', ['A', ['D', ['C', 'E']]]], ['G', [undef, ['I', ['H', undef]]]]]];

Perl::diag("in multi_tree.pl, have \$nested_arrayrefs_chars =\n" . Perl::DUMPER($nested_arrayrefs_chars) . "\n");

my scalartype_binarytreeref $tree = scalar_binarytreeref->new_from_nested_arrayrefs($nested_arrayrefs_chars);
#my scalartype_binarytreeref $tree = scalar_binarytreeref->new_from_nested_arrayrefs([2112, [[33, [17, 71]], [44, [23, [1.21, [undef, 55]]]]]]);
=UNUSED CODE
my scalartype_binarytreeref $tree = scalar_binarytreeref->new_from_nested_arrayrefs(
[2112, 
	[[33, 
		[17, 
		 71]], 
	 [44, 
	 	[23, 
	 	[1.21, 
	 		[undef, 
	 		 55]]]]]]);
=cut	 		 
=TREE DIAGRAM
					2112
			33				44
		17		71		23		1.21
							undef	55
=cut

Perl::diag("in multi_tree.pl, have \$tree =\n" . Perl::DUMPER($tree) . "\n");

our string $callback_value = sub {(my binarytreenoderef $node) = @_;
;
	return $node if (ref(\$node) eq 'SCALAR');
	return $node->{data};
};

my $retval_depthfirst_preorder = $tree->traverse_depthfirst_preorder($callback_value);
Perl::diag("in multi_tree.pl, have \$retval_depthfirst_preorder =\n" . Perl::DUMPER($retval_depthfirst_preorder) . "\n");

my $retval_breadthfirst_queue = $tree->traverse_breadthfirst_queue($callback_value);
Perl::diag("in multi_tree.pl, have \$retval_breadthfirst_queue =\n" . Perl::DUMPER($retval_breadthfirst_queue) . "\n");

my $retval_nested_arrayrefs = $tree->to_nested_arrayrefs();
Perl::diag("in multi_tree.pl, have \$retval_nested_arrayrefs =\n" . Perl::DUMPER($retval_nested_arrayrefs) . "\n");



