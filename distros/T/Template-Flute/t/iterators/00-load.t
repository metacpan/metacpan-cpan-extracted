#!perl -T

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Template::Flute::Iterator' ) || print "Bail out!
";
}

