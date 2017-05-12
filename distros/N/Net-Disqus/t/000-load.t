#!/usr/bin/env perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'Net::Disqus' ) || print "Bail out!\n";
    use_ok( 'Net::Disqus::Exception' ) || print "Bail out!\n";
    use_ok( 'Net::Disqus::UserAgent' ) || print "Bail out!\n";
}

diag( "Testing Net::Disqus $Net::Disqus::VERSION, Perl $], $^X" );
