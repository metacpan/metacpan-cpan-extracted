#!/usr/bin/env perl
# t/04b-metadata.t — Tests for Document Information Dictionary (metadata).

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use_ok('PDF::Make::Document');

# Basic metadata getters/setters
{
    my $doc = PDF::Make::Document->new;
    isa_ok($doc, 'PDF::Make::Document');

    # Initially metadata should be undef
    is($doc->title, undef, 'title initially undef');
    is($doc->author, undef, 'author initially undef');
    is($doc->subject, undef, 'subject initially undef');
    is($doc->keywords, undef, 'keywords initially undef');
    is($doc->creator, undef, 'creator initially undef');
}

# Setting and getting title
{
    my $doc = PDF::Make::Document->new;

    my $ret = $doc->title('My Test Document');
    is($ret, 'My Test Document', 'title setter returns value');

    is($doc->title, 'My Test Document', 'title getter returns set value');
}

# Setting and getting author
{
    my $doc = PDF::Make::Document->new;

    $doc->author('Jane Doe');
    is($doc->author, 'Jane Doe', 'author round-trip');
}

# Setting and getting subject
{
    my $doc = PDF::Make::Document->new;

    $doc->subject('Test PDF for metadata');
    is($doc->subject, 'Test PDF for metadata', 'subject round-trip');
}

# Setting and getting keywords
{
    my $doc = PDF::Make::Document->new;

    $doc->keywords('test pdf perl xs');
    is($doc->keywords, 'test pdf perl xs', 'keywords round-trip');
}

# Setting and getting creator
{
    my $doc = PDF::Make::Document->new;

    $doc->creator('Test Application');
    is($doc->creator, 'Test Application', 'creator round-trip');
}

# Setting and getting producer
{
    my $doc = PDF::Make::Document->new;

    $doc->producer('Custom Producer/1.0');
    is($doc->producer, 'Custom Producer/1.0', 'producer round-trip');
}

# Generic set_meta / get_meta
{
    my $doc = PDF::Make::Document->new;

    $doc->set_meta('Title', 'Via set_meta');
    is($doc->get_meta('Title'), 'Via set_meta', 'set_meta/get_meta works');

    # Should also be accessible via convenience method
    is($doc->title, 'Via set_meta', 'title() sees set_meta value');
}

# All metadata fields together
{
    my $doc = PDF::Make::Document->new;

    $doc->title('Complete Test');
    $doc->author('Test Author');
    $doc->subject('Test Subject');
    $doc->keywords('test metadata complete');
    $doc->creator('Test Creator App');
    $doc->producer('Test Producer/2.0');

    is($doc->title, 'Complete Test', 'all fields - title');
    is($doc->author, 'Test Author', 'all fields - author');
    is($doc->subject, 'Test Subject', 'all fields - subject');
    is($doc->keywords, 'test metadata complete', 'all fields - keywords');
    is($doc->creator, 'Test Creator App', 'all fields - creator');
    is($doc->producer, 'Test Producer/2.0', 'all fields - producer');
}

# Overwriting metadata
{
    my $doc = PDF::Make::Document->new;

    $doc->title('First Title');
    is($doc->title, 'First Title', 'first title set');

    $doc->title('Second Title');
    is($doc->title, 'Second Title', 'title overwritten');
}

# Metadata in PDF output
{
    my $doc = PDF::Make::Document->new;
    my $cat_num = $doc->add("Catalog");
    $doc->set_root($cat_num);

    $doc->title('PDF Output Test');
    $doc->author('Output Author');

    my $bytes = $doc->to_bytes;
    ok(length($bytes) > 100, 'PDF has content');

    # Check metadata appears in output
    like($bytes, qr{/Title}, 'output contains /Title');
    like($bytes, qr{PDF Output Test}, 'output contains title value');
    like($bytes, qr{/Author}, 'output contains /Author');
    like($bytes, qr{Output Author}, 'output contains author value');
}

# Auto-set Producer and dates on write
{
    my $doc = PDF::Make::Document->new;
    my $cat_num = $doc->add("Catalog");
    $doc->set_root($cat_num);

    # Don't set producer manually
    my $bytes = $doc->to_bytes;

    # Producer should be auto-set
    like($bytes, qr{/Producer}, 'output contains /Producer');
    like($bytes, qr{PDF-Make/}, 'producer is PDF-Make');

    # Dates should be auto-set
    like($bytes, qr{/CreationDate}, 'output contains /CreationDate');
    like($bytes, qr{/ModDate}, 'output contains /ModDate');
    like($bytes, qr{D:\d{14}}, 'date has D:YYYYMMDDHHMMSS format');
}

# Custom producer is preserved
{
    my $doc = PDF::Make::Document->new;
    my $cat_num = $doc->add("Catalog");
    $doc->set_root($cat_num);

    $doc->producer('My Custom Producer');

    my $bytes = $doc->to_bytes;
    like($bytes, qr{My Custom Producer}, 'custom producer preserved');
}

# File output with metadata
{
    my $doc = PDF::Make::Document->new;
    my $cat_num = $doc->add("Catalog");
    $doc->set_root($cat_num);

    $doc->title('File Test');
    $doc->author('File Author');

    my ($fh, $filename) = tempfile(SUFFIX => '.pdf', UNLINK => 1);
    close($fh);

    $doc->to_file($filename);

    ok(-e $filename, 'file created');
    ok(-s $filename > 50, 'file has content');

    # Read back and verify metadata
    open(my $in, '<:raw', $filename) or die "Cannot read $filename: $!";
    my $content = do { local $/; <$in> };
    close($in);

    like($content, qr{/Title}, 'file contains /Title');
    like($content, qr{File Test}, 'file contains title');
    like($content, qr{/Author}, 'file contains /Author');
    like($content, qr{File Author}, 'file contains author');
}

# Unicode in metadata
{
    my $doc = PDF::Make::Document->new;

    $doc->title('Tëst Üñïcödé');
    is($doc->title, 'Tëst Üñïcödé', 'unicode in title');

    $doc->author('Äûthör Ñàmé');
    is($doc->author, 'Äûthör Ñàmé', 'unicode in author');
}

# Empty string metadata
{
    my $doc = PDF::Make::Document->new;

    $doc->title('');
    # Empty strings in PDF become zero-length strings, which C returns as NULL
    # This is acceptable behavior - empty metadata is effectively "not set"
    my $title = $doc->title;
    ok(!defined($title) || $title eq '', 'empty string title is undef or empty');
}

# Long metadata value
{
    my $doc = PDF::Make::Document->new;

    my $long_title = 'A' x 1000;
    $doc->title($long_title);
    is($doc->title, $long_title, 'long title preserved');
}

# Chained metadata calls
{
    my $doc = PDF::Make::Document->new;

    # Each setter returns the value, allowing some chaining patterns
    my $t = $doc->title('Chained');
    my $a = $doc->author('Author');

    is($t, 'Chained', 'chained title return');
    is($a, 'Author', 'chained author return');
}

done_testing();
