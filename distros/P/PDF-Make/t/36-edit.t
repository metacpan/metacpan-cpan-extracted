#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 33;

use PDF::Make::Document;

# Test 1: page_count
{
    my $doc = PDF::Make::Document->new;
    is($doc->page_count, 0, 'new document has 0 pages');
}

# Test 2-4: add_page and page_count
{
    my $doc = PDF::Make::Document->new;
    my $p1 = $doc->add_page(612, 792);  # Letter
    ok($p1, 'add_page returns page');
    is($doc->page_count, 1, 'page_count is 1 after add');
    
    my $p2 = $doc->add_page(595, 842);  # A4
    is($doc->page_count, 2, 'page_count is 2 after second add');
}

# Test 5-6: get_page
{
    my $doc = PDF::Make::Document->new;
    $doc->add_page(612, 792);
    $doc->add_page(595, 842);
    
    my $page = $doc->get_page(0);
    ok($page, 'get_page(0) returns page');
    is($doc->get_page(1) && 1, 1, 'get_page(1) returns page');
}

# Test 7: get_page out of bounds
{
    my $doc = PDF::Make::Document->new;
    $doc->add_page;
    
    eval { $doc->get_page(5) };
    like($@, qr/invalid page index/, 'get_page out of bounds croaks');
}

# Test 8-10: remove_page
{
    my $doc = PDF::Make::Document->new;
    $doc->add_page;
    $doc->add_page;
    $doc->add_page;
    is($doc->page_count, 3, 'have 3 pages');
    
    $doc->remove_page(1);  # Remove middle
    is($doc->page_count, 2, 'remove_page reduces count');
    
    eval { $doc->remove_page(10) };
    like($@, qr/failed to remove/, 'remove_page out of bounds croaks');
}

# Test 11-13: move_page
{
    my $doc = PDF::Make::Document->new;
    my $p1 = $doc->add_page(100, 100);
    my $p2 = $doc->add_page(200, 200);
    my $p3 = $doc->add_page(300, 300);
    
    # Move page 2 to position 0
    $doc->move_page(2, 0);
    is($doc->page_count, 3, 'move_page preserves count');
    
    # The page originally at index 2 should now be at 0
    # We can't easily verify contents from Perl, but at least it doesn't crash
    pass('move_page completed without error');
    
    eval { $doc->move_page(10, 0) };
    like($@, qr/failed to move/, 'move_page out of bounds croaks');
}

# Test 14-17: rotate_page
{
    my $doc = PDF::Make::Document->new;
    $doc->add_page;
    
    # These should work
    $doc->rotate_page(0, 90);
    pass('rotate_page 90 works');
    
    $doc->rotate_page(0, 180);
    pass('rotate_page 180 works');
    
    $doc->rotate_page(0, 270);
    pass('rotate_page 270 works');
    
    eval { $doc->rotate_page(0, 45) };
    like($@, qr/invalid rotation/, 'rotate_page invalid angle croaks');
}

# Test 18-20: duplicate_page
{
    my $doc = PDF::Make::Document->new;
    $doc->add_page(612, 792);
    is($doc->page_count, 1, 'start with 1 page');
    
    $doc->duplicate_page(0);
    is($doc->page_count, 2, 'duplicate_page adds a page');
    
    eval { $doc->duplicate_page(10) };
    like($@, qr/failed to duplicate/, 'duplicate_page out of bounds croaks');
}

# Test 21-23: Combined operations - create document with pages and output
{
    my $doc = PDF::Make::Document->new;
    $doc->title('Test Edit Document');
    
    # Add three pages
    $doc->add_page(612, 792);
    $doc->add_page(612, 792);
    $doc->add_page(612, 792);
    
    # Rotate first page
    $doc->rotate_page(0, 90);
    
    # Duplicate middle page
    $doc->duplicate_page(1);
    
    # Remove last page
    $doc->remove_page(3);
    
    is($doc->page_count, 3, 'operations leave 3 pages');
    
    # Should be able to output
    my $bytes = $doc->to_bytes;
    ok(length($bytes) > 100, 'document produces output');
    like($bytes, qr/%PDF-2\.0/, 'output starts with PDF header');
}

# Test 24-27: Text annotations
{
    my $doc = PDF::Make::Document->new;
    $doc->add_page(612, 792);
    
    my $annot = $doc->add_text_annot(100, 700, 120, 720, "This is a note");
    ok($annot > 0, 'add_text_annot returns object number');
    
    my $annot2 = $doc->add_text_annot(100, 600, 120, 620, "Comment note", "Comment", 1);
    ok($annot2 > 0, 'add_text_annot with icon and open flag');
    
    my $bytes = $doc->to_bytes;
    like($bytes, qr{/Subtype\s*/Text}, 'output contains Text annotation');
    like($bytes, qr{/Contents}, 'output contains Contents');
}

# Test 28-30: Link annotations
{
    my $doc = PDF::Make::Document->new;
    $doc->add_page(612, 792);
    $doc->add_page(612, 792);
    
    my $link = $doc->add_link_uri(100, 700, 200, 720, "https://example.com");
    ok($link > 0, 'add_link_uri returns object number');
    
    my $goto = $doc->add_link_goto(100, 600, 200, 620, 1);
    ok($goto > 0, 'add_link_goto returns object number');
    
    my $bytes = $doc->to_bytes;
    like($bytes, qr{/Subtype\s*/Link}, 'output contains Link annotation');
}

# Test 31-33: Stamp annotations
{
    my $doc = PDF::Make::Document->new;
    $doc->add_page(612, 792);
    
    my $stamp = $doc->add_stamp(100, 400, 300, 500, "Draft");
    ok($stamp > 0, 'add_stamp returns object number');
    
    my $stamp2 = $doc->add_stamp(100, 200, 300, 300, "Confidential");
    ok($stamp2 > 0, 'add_stamp Confidential returns object number');
    
    my $bytes = $doc->to_bytes;
    like($bytes, qr{/Subtype\s*/Stamp}, 'output contains Stamp annotation');
}
