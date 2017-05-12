#!/usr/bin/perl -w
use strict;
use Test;
BEGIN { plan tests => 3 }

eval "use XML::SAX";
if ($@) {
    skip("XML::SAX not available") foreach 1..3;
    exit 0;
} 

eval "use SVG::Parser::SAX";
ok(not $@);

my $parser=new SVG::Parser::SAX;
ok(defined $parser);

open (FH,"t/in/svg.xml") or die $!;
my $svg=$parser->parsefile(*FH);
ok(defined $svg);
