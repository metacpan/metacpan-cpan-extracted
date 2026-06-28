#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 21;

use PDF::Make::Document;

# Test 1: Create document with outline
{
    my $doc = PDF::Make::Document->new;
    $doc->add_page(612, 792);
    
    my $outline = $doc->add_outline('Chapter 1', 0);
    ok(defined $outline, 'add_outline returns outline object');
    isa_ok($outline, 'PDF::Make::Outline', 'outline is correct class');
}

# Test 2-4: Outline title and properties
{
    my $doc = PDF::Make::Document->new;
    $doc->add_page(612, 792);
    $doc->add_page(612, 792);
    
    my $outline = $doc->add_outline('Introduction', 0, 'Fit');
    is($outline->title, 'Introduction', 'title accessor works');
    is($outline->dest_page, 0, 'dest_page returns correct page index');
    is($outline->is_open, 1, 'outline is open by default');
}

# Test 5-6: Set open/closed
{
    my $doc = PDF::Make::Document->new;
    $doc->add_page(612, 792);
    
    my $outline = $doc->add_outline('Test', 0);
    $outline->set_open(0);
    is($outline->is_open, 0, 'set_open(0) closes outline');
    
    $outline->set_open(1);
    is($outline->is_open, 1, 'set_open(1) opens outline');
}

# Test 7-10: Add children
{
    my $doc = PDF::Make::Document->new;
    $doc->add_page(612, 792);
    $doc->add_page(612, 792);
    $doc->add_page(612, 792);
    
    my $root = $doc->add_outline('Part 1', 0);
    my $ch1 = $root->add_child('Chapter 1', 1);
    ok(defined $ch1, 'add_child returns child outline');
    isa_ok($ch1, 'PDF::Make::Outline', 'child is correct class');
    is($ch1->title, 'Chapter 1', 'child title is correct');
    is($ch1->dest_page, 1, 'child dest_page is correct');
}

# Test 11-13: Children list
{
    my $doc = PDF::Make::Document->new;
    $doc->add_page(612, 792);
    $doc->add_page(612, 792);
    $doc->add_page(612, 792);
    
    my $root = $doc->add_outline('Book', 0);
    $root->add_child('Chapter 1', 0);
    $root->add_child('Chapter 2', 1);
    $root->add_child('Chapter 3', 2);
    
    ok($root->has_children, 'has_children returns true');
    
    my @children = $root->children;
    is(scalar(@children), 3, 'children returns 3 items');
    is($children[0]->title, 'Chapter 1', 'first child is Chapter 1');
}

# Test 14-15: Sibling navigation
{
    my $doc = PDF::Make::Document->new;
    $doc->add_page(612, 792);
    $doc->add_page(612, 792);
    
    my $root = $doc->add_outline('Book', 0);
    my $ch1 = $root->add_child('First', 0);
    my $ch2 = $root->add_child('Second', 1);
    
    my $next = $ch1->next_sibling;
    ok(defined $next, 'next_sibling returns sibling');
    is($next->title, 'Second', 'next_sibling is correct');
}

# Test 16-17: Parent navigation
{
    my $doc = PDF::Make::Document->new;
    $doc->add_page(612, 792);
    $doc->add_page(612, 792);
    
    my $root = $doc->add_outline('Root', 0);
    my $child = $root->add_child('Child', 1);
    
    my $parent = $child->parent;
    ok(defined $parent, 'parent returns parent');
    is($parent->title, 'Root', 'parent is correct');
}

# Test 18-20: Output with outline
{
    my $doc = PDF::Make::Document->new;
    $doc->title('Outline Test Document');
    
    $doc->add_page(612, 792);
    $doc->add_page(612, 792);
    $doc->add_page(612, 792);
    
    my $root = $doc->add_outline('Table of Contents', 0);
    $root->add_child('Introduction', 0);
    $root->add_child('Main Content', 1);
    $root->add_child('Conclusion', 2);
    
    my $bytes = $doc->to_bytes;
    ok(length($bytes) > 100, 'document with outline produces output');
    like($bytes, qr/%PDF-2\.0/, 'output starts with PDF header');
    like($bytes, qr{/Outlines}, 'output contains /Outlines reference');
}
