#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use SVG;

# RT136789
# https://rt.cpan.org/Public/Bug/Display.html?id=136789

my $svg = SVG->new(width => 100, height => 100);

# Test 1: comment() behavior
my $comment_text = "RT136789 Test Comment";
$svg->comment($comment_text);

# Test 2: desc() behavior
$svg->desc(id => 'desc-id')->cdata('Accessible Description');

my $xml = $svg->xmlify();

# Validation
like($xml, qr//, 'comment() should produce XML comment tags');
unlike($xml, qr/<comment/, 'comment() should NOT produce a <comment> element');
like($xml, qr/<desc id="desc-id">Accessible Description<\/desc>/, 'desc() should produce a <desc> element');

done_testing;
