#!perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

BEGIN { use_ok('PDF::Make::Document') }

# Test constructor
{
    my $doc = PDF::Make::Document->new;
    ok($doc, 'new() creates a document');
    isa_ok($doc, 'PDF::Make::Document');
}

# Test add simple objects
{
    my $doc = PDF::Make::Document->new;
    my $n1 = $doc->add(42);
    my $n2 = $doc->add(3.14);
    my $n3 = $doc->add("Hello");

    is($n1, 1, 'first object number is 1');
    is($n2, 2, 'second object number is 2');
    is($n3, 3, 'third object number is 3');
}

# Test set_root
{
    my $doc = PDF::Make::Document->new;
    my $num = $doc->add(42);
    $doc->set_root($num);
    pass('set_root does not crash');
}

# Test to_bytes produces valid PDF structure
{
    my $doc = PDF::Make::Document->new;

    # Add a minimal catalog-like object
    my $cat_num = $doc->add("Catalog placeholder");
    $doc->set_root($cat_num);

    my $bytes = $doc->to_bytes;
    ok(length($bytes) > 50, 'to_bytes produces output');

    # Check PDF header
    like($bytes, qr/^%PDF-2\.0/, 'starts with PDF header');

    # Check binary comment (4 high bytes after %)
    like($bytes, qr/^%PDF-2\.0\n%[\x80-\xff]{4}/, 'has binary comment');

    # Check structure markers
    like($bytes, qr/1 0 obj/, 'contains indirect object');
    like($bytes, qr/endobj/, 'contains endobj');
    like($bytes, qr/xref/, 'contains xref');
    like($bytes, qr/trailer/, 'contains trailer');
    like($bytes, qr/startxref/, 'contains startxref');
    like($bytes, qr/%%EOF/, 'ends with EOF marker');
}

# Test trailer contains required elements
{
    my $doc = PDF::Make::Document->new;
    my $cat_num = $doc->add("Catalog");
    $doc->set_root($cat_num);

    my $bytes = $doc->to_bytes;

    # Check trailer elements
    like($bytes, qr{/Size \d+}, 'trailer has /Size');
    like($bytes, qr{/Root \d+ \d+ R}, 'trailer has /Root reference');
    like($bytes, qr{/ID\[<[0-9A-F]{32}><[0-9A-F]{32}>\]}, 'trailer has /ID array');
}

# Test set_info adds /Info to trailer
{
    my $doc = PDF::Make::Document->new;

    my $info_num = $doc->add("Info dictionary");
    $doc->set_info($info_num);

    my $cat_num = $doc->add("Catalog");
    $doc->set_root($cat_num);

    my $bytes = $doc->to_bytes;

    like($bytes, qr{/Info \d+ \d+ R}, 'trailer has /Info reference');
}

# Test to_file writes to disk
{
    my $doc = PDF::Make::Document->new;
    my $cat_num = $doc->add("Catalog");
    $doc->set_root($cat_num);

    my ($fh, $filename) = tempfile(SUFFIX => '.pdf', UNLINK => 1);
    close($fh);

    $doc->to_file($filename);

    ok(-e $filename, 'to_file creates file');
    ok(-s $filename > 50, 'file has content');

    # Read back and verify
    open(my $in, '<:raw', $filename) or die "Cannot read $filename: $!";
    my $content = do { local $/; <$in> };
    close($in);

    like($content, qr/^%PDF-2\.0/, 'file starts with PDF header');
    like($content, qr/%%EOF/, 'file ends with EOF');
}

# Test xref table format
{
    my $doc = PDF::Make::Document->new;

    # Add multiple objects
    for (1..5) {
        $doc->add($_);
    }
    my $cat_num = $doc->add("Catalog");
    $doc->set_root($cat_num);

    my $bytes = $doc->to_bytes;

    # Check xref format: "xref\n0 N\n"
    # Note: 6 user objects + 1 auto-generated Info dict + entry 0 = 8 entries
    like($bytes, qr/xref\n0 8\n/, 'xref has correct entry count');

    # Check first entry (free list head)
    like($bytes, qr/0000000000 65535 f /, 'xref entry 0 is free list head');
}

# Test multiple documents have unique IDs
{
    my $doc1 = PDF::Make::Document->new;
    $doc1->add("Test");
    $doc1->set_root(1);

    my $doc2 = PDF::Make::Document->new;
    $doc2->add("Test");
    $doc2->set_root(1);

    my $bytes1 = $doc1->to_bytes;
    my $bytes2 = $doc2->to_bytes;

    # Extract ID arrays
    my ($id1) = $bytes1 =~ m{/ID\[(<[^>]+>)};
    my ($id2) = $bytes2 =~ m{/ID\[(<[^>]+>)};

    isnt($id1, $id2, 'different documents have different IDs');
}

# Test DESTROY (implicit via scope)
{
    my $doc = PDF::Make::Document->new;
    $doc->add(42);
    # Doc goes out of scope - should not crash
}
pass('DESTROY does not crash');

done_testing();
