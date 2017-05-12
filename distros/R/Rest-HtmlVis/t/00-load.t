#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 5;

BEGIN {
    use_ok( 'Rest::HtmlVis' ) || print "Bail out!\n";
    use_ok( 'Rest::HtmlVis::Key' ) || print "Bail out!\n";
    use_ok( 'Rest::HtmlVis::Base' ) || print "Bail out!\n";
    use_ok( 'Rest::HtmlVis::Content' ) || print "Bail out!\n";
    use_ok( 'Rest::HtmlVis::Events' ) || print "Bail out!\n";
}

diag( "Testing Rest::HtmlVis $Rest::HtmlVis::VERSION, Perl $], $^X" );
