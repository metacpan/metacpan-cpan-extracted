#!/usr/bin/perl
use strict;
use warnings;
use Pod::Literate;
## No options at this time
my $parser=Pod::Literate->new();
$parser->accept_targets('literate','literate:command');
$parser->expand_verbatim_tabs(0);
$parser->parse_from_file(shift(@ARGV));

