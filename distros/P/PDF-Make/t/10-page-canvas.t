#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 20;

# Test loading Page and Canvas modules
use_ok('PDF::Make::Page', ':fonts');
use_ok('PDF::Make::Canvas', ':all');

# Test Page font constants
is(TIMES_ROMAN(),   0, 'TIMES_ROMAN constant');
is(HELVETICA(),     4, 'HELVETICA constant');
is(COURIER(),       8, 'COURIER constant');
is(SYMBOL(),        12, 'SYMBOL constant');
is(ZAPFDINGBATS(),  13, 'ZAPFDINGBATS constant');

# Test Canvas constants
is(CAP_BUTT(),   0, 'CAP_BUTT constant');
is(CAP_ROUND(),  1, 'CAP_ROUND constant');
is(CAP_SQUARE(), 2, 'CAP_SQUARE constant');

is(JOIN_MITER(), 0, 'JOIN_MITER constant');
is(JOIN_ROUND(), 1, 'JOIN_ROUND constant');
is(JOIN_BEVEL(), 2, 'JOIN_BEVEL constant');

is(RENDER_FILL(),    0, 'RENDER_FILL constant');
is(RENDER_STROKE(),  1, 'RENDER_STROKE constant');
is(RENDER_INVISIBLE(), 3, 'RENDER_INVISIBLE constant');

# Test Canvas creation and basic operations
my $canvas = PDF::Make::Canvas->new;
isa_ok($canvas, 'PDF::Make::Canvas', 'Canvas creation');
is($canvas->len, 0, 'Empty canvas has zero length');

# Test fluent interface for graphics
$canvas->q
       ->w(2)
       ->re(100, 100, 200, 150)
       ->S
       ->Q;
ok($canvas->len > 0, 'Canvas has content after drawing');

my $bytes = $canvas->to_bytes;
like($bytes, qr/q\s+2\s+w\s+100\s+100\s+200\s+150\s+re\s+S\s+Q/s, 'Graphics output matches expected');
