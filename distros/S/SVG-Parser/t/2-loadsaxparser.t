#!/usr/bin/perl -w
use strict;
use Test;
BEGIN { plan tests => 1 }

eval "use XML::SAX";
if ($@) {
    skip("XML::SAX not available");
} else {
    eval "use SVG::Parser::SAX";
    ok(not $@);
}
