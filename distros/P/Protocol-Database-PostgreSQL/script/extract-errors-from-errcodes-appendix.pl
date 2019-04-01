#!/usr/bin/env perl
use strict;
use warnings;

use HTML::TreeBuilder;

my $html = HTML::TreeBuilder->new;
# https://www.postgresql.org/docs/current/static/errcodes-appendix.html
$html->parse_file('errcodes-appendix.html') or die;

my %error;
my ($tbl) = $html->look_down(summary => 'PostgreSQL Error Codes');
for my $row ($tbl->look_down(_tag => 'tr')) {
    my ($literal) = $row->look_down(class => 'literal');
    my ($symbol) = $row->look_down(class => 'symbol');
    next unless $literal && $symbol;
    $error{$literal->as_text} = $symbol->as_text;
}

print "    '$_' => '$error{$_}',\n" for sort keys %error;

