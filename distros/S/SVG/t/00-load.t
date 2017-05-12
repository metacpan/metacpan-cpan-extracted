#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
    use_ok('SVG')            || print "Bail out!\n";
    use_ok('SVG::DOM')       || print "Bail out!\n";
    use_ok('SVG::Element')   || print "Bail out!\n";
    use_ok('SVG::Extension') || print "Bail out!\n";
    use_ok('SVG::XML')       || print "Bail out!\n";
}

diag("Testing SVG $SVG::VERSION, Perl $], $^X");
