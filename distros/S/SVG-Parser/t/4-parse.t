#!/usr/bin/perl -w
use strict;
use Test;
BEGIN { plan tests => 3 }

use SVG::Parser;
ok(1);

my $xml;
{
    push @ARGV,"t/in/svg.xml";
    local $/=undef;
    $xml=<>;
}

my $parser=new SVG::Parser;
ok(defined $parser);

my $svg=$parser->parse($xml);
ok(defined $svg);

