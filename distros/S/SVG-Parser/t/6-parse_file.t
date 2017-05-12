#!/usr/bin/perl -w
use strict;
use Test;
BEGIN { plan tests => 3 }

use SVG::Parser;
ok(1);

my $parser=new SVG::Parser;
ok(defined $parser);

my $svg=$parser->parse_file("t/in/svg.xml");
ok(defined $svg);
