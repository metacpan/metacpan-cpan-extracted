#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 13;

BEGIN {
    use_ok('PDF::Make::Document');
    use_ok('PDF::Make::Structure');
}

my $doc = PDF::Make::Document->new;
$doc->add_page(612, 792);

# Create structure tree
my $tree = PDF::Make::Structure->create_tree($doc);
ok($tree, 'structure tree created');

my $root = $tree->root;
ok($root, 'root element');
is($root->type, 'Document', 'root type is Document');

# Add children
my $h1 = $root->add_child('H1');
ok($h1, 'H1 created');
is($h1->type, 'H1', 'child type is H1');

my $p = $root->add_child('P');
is($p->type, 'P', 'paragraph type');

my $fig = $root->add_child('Figure');
$fig->alt_text('Test figure');
$fig->lang('en-US');

is($root->child_count, 3, 'root has 3 children');

my $child0 = $root->child_at(0);
is($child0->type, 'H1', 'child_at(0) is H1');

# Verify PDF
my $bytes = $doc->to_bytes;
like($bytes, qr/StructTreeRoot/, 'PDF has /StructTreeRoot');
like($bytes, qr/StructElem/, 'PDF has /Type /StructElem');
like($bytes, qr/MarkInfo/, 'PDF has /MarkInfo');

done_testing;
