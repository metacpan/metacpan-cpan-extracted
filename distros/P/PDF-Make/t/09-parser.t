#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 15;
use File::Spec;

BEGIN { use_ok('PDF::Make::Parser') }

# Get the fixtures directory
my $corpus_dir = File::Spec->catdir('t', 'fixtures');
my $hello_pdf = File::Spec->catfile($corpus_dir, 'hello_world.pdf');

# Test 1: Load from file
my $parser = eval { PDF::Make::Parser->from_file($hello_pdf) };
ok($parser, 'from_file creates parser');
is(ref($parser), 'PDF::Make::Parser', 'parser is correct class');

# Test 2: Parse the file
eval { $parser->parse };
ok(!$@, 'parse succeeds') or diag("Parse error: $@");

# Test 3: Check xref size (should have at least 3 objects)
my $xref_size = $parser->xref_size;
ok($xref_size >= 3, "xref_size >= 3 (got $xref_size)");

# Test 4: Check root reference
my $root_num = $parser->root_num;
ok($root_num > 0, "root_num > 0 (got $root_num)");

my $root_gen = $parser->root_gen;
ok(defined $root_gen, "root_gen defined (got $root_gen)");

# Test 5: Resolve the root object
my $root_kind = $parser->resolve($root_num, $root_gen);
ok(defined $root_kind, 'resolved root object');
# Kind 7 = PDFMAKE_DICT
is($root_kind, 7, 'root object is a dict (kind=7)');

# Test 6: Get document
my $doc = eval { $parser->document };
ok($doc, 'document() returns document');
isa_ok($doc, 'PDF::Make::Document', 'document is correct class');

# Test 7: Parser resolve (get_object is via parser, not doc)
my $obj_kind = $parser->resolve($root_num, $root_gen);
is($obj_kind, 7, 'resolve returns root dict (kind=7)');

# Test parsing from bytes (minimal PDF)
{
    my $minimal_pdf = join('',
        "%PDF-1.4\n",
        "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n",
        "2 0 obj\n<< /Type /Pages /Count 0 /Kids [] >>\nendobj\n",
        "xref\n",
        "0 3\n",
        "0000000000 65535 f \n",
        "0000000009 00000 n \n",
        "0000000058 00000 n \n",
        "trailer\n<< /Size 3 /Root 1 0 R >>\n",
        "startxref\n110\n%%EOF"
    );

    my $parser = PDF::Make::Parser->from_bytes($minimal_pdf);
    ok($parser, 'from_bytes creates parser');

    $parser->parse;
    is($parser->xref_size, 3, 'minimal PDF has xref_size=3');
    is($parser->root_num, 1, 'minimal PDF root is object 1');
}

done_testing();
