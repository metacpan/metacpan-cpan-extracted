#!/usr/bin/perl -w
use strict;
use Test;
BEGIN { plan tests => 1 }

eval "use XML::Parser";
if ($@) {
    skip("XML::Parser not available");
} else {
    eval "use SVG::Parser::Expat";
    ok(not $@);
}
