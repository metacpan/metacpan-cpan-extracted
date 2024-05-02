use strict;
use warnings;

use Tags::HTML::Tree;
use Tags::Output::Structure;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Tree;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Tree->new(
	'tags' => $tags,
);
my $tree = Tree->new('Root');
$obj->init($tree);
$obj->process;
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'ul'],
		['a', 'class', 'tree'],
		['b', 'li'],
		['d', 'Root'],
		['e', 'li'],
		['e', 'ul'],
	],
	'Tags code for Tree (only root element).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Tree->new(
	'tags' => $tags,
);
$tree = Tree->new('Root');
$tree->add_child(Tree->new('Leaf 1'));
$tree->add_child(Tree->new('Leaf 2'));
$obj->init($tree);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'ul'],
		['a', 'class', 'tree'],
		['b', 'li'],
		['b', 'span'],
		['a', 'class', 'caret'],
		['d', 'Root'],
		['e', 'span'],
		['b', 'ul'],
		['a', 'class', 'nested'],
		['b', 'li'],
		['d', 'Leaf 1'],
		['e', 'li'],
		['b', 'li'],
		['d', 'Leaf 2'],
		['e', 'li'],
		['e', 'ul'],
		['e', 'li'],
		['e', 'ul'],
	],
	'Tags code for Tree (root with two leafs).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Tree->new(
	'tags' => $tags,
);
$tree = Tree->new('Root');
my $node_1 = Tree->new('Node 1');
$tree->add_child($node_1); 
$node_1->add_child(Tree->new('Leaf 1'));
$node_1->add_child(Tree->new('Leaf 2'));
my $node_2 = Tree->new('Node 2');
$tree->add_child($node_2); 
$node_2->add_child(Tree->new('Leaf 3'));
$obj->init($tree);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'ul'],
		['a', 'class', 'tree'],
		['b', 'li'],
		['b', 'span'],
		['a', 'class', 'caret'],
		['d', 'Root'],
		['e', 'span'],
		['b', 'ul'],
		['a', 'class', 'nested'],

		['b', 'li'],
		['b', 'span'],
		['a', 'class', 'caret'],
		['d', 'Node 1'],
		['e', 'span'],
		['b', 'ul'],
		['a', 'class', 'nested'],
		['b', 'li'],
		['d', 'Leaf 1'],
		['e', 'li'],
		['b', 'li'],
		['d', 'Leaf 2'],
		['e', 'li'],
		['e', 'ul'],
		['e', 'li'],

		['b', 'li'],
		['b', 'span'],
		['a', 'class', 'caret'],
		['d', 'Node 2'],
		['e', 'span'],
		['b', 'ul'],
		['a', 'class', 'nested'],
		['b', 'li'],
		['d', 'Leaf 3'],
		['e', 'li'],
		['e', 'ul'],
		['e', 'li'],

		['e', 'ul'],
		['e', 'li'],
		['e', 'ul'],
	],
	'Tags code for Tree (root with advanced structure).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Tree->new(
	'tags' => $tags,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[],
	'Tags code for Tree (no init).',
);

