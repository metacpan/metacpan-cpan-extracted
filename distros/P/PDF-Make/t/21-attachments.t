#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 14;

BEGIN {
    use_ok('PDF::Make::Document');
    use_ok('PDF::Make::Attachment');
}

my $doc = PDF::Make::Document->new;
$doc->add_page(612, 792);

# Attach from data
my $att = PDF::Make::Attachment->attach($doc,
    name     => 'test.txt',
    data     => "Hello from PDF::Make!\n",
    mime     => 'text/plain',
    description => 'Test file',
);
ok($att, 'attachment created');
is($att->name, 'test.txt', 'name correct');
is($att->filename, 'test.txt', 'filename correct');
is($att->mime_type, 'text/plain', 'MIME type correct');
is($att->size, 22, 'size correct');

# Extract data
my $extracted = $att->data;
is($extracted, "Hello from PDF::Make!\n", 'data round-trip');

# Second attachment
my $att2 = PDF::Make::Attachment->attach($doc,
    name => 'config.json',
    data => '{"key":"value"}',
);
ok($att2, 'second attachment');
is($att2->mime_type, 'application/json', 'auto MIME detection');

# Write and verify PDF
my $bytes = $doc->to_bytes;
like($bytes, qr/EmbeddedFiles/, 'PDF has /EmbeddedFiles');
like($bytes, qr/Filespec/, 'PDF has /Type /Filespec');
like($bytes, qr/EmbeddedFile/, 'PDF has /Type /EmbeddedFile');
like($bytes, qr/test\.txt/, 'PDF contains filename');

done_testing;
