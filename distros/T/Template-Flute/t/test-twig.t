#!/usr/bin/env perl

use strict;
use warnings;
use XML::Twig;
use Test::More tests => 3;


my $parser = XML::Twig->new();

my $value =<< 'EOF';
<h1>Here&amp;there</h1>
EOF

my $html = $parser->safe_parse_html($value);
if ($@) {
    diag $@;
}
ok($html, "Entities parsed without errors");

$value =<< 'EOF';
<h1 style="display:none">Here &amp; there</h1>
EOF

$html = $parser->safe_parse_html($value);
if ($@) {
    diag $@;
}
ok($html);

$html = $parser->safe_parse_html($value);
my @elts = $html->root()->get_xpath("//body");
is($elts[0]->first_child->{att}->{style}, "display:none",
   "style found with default converter");

