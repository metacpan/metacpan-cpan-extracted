use Test::More tests => 1;

BEGIN {
    use_ok( 'SWISH::Filters::ImageToMD5Xml' ) || print "Bail out!\n";
}

diag( "Testing SWISH::Filters::ImageToMD5Xml $SWISH::Filters::ImageToMD5Xml::VERSION, Perl $], $^X" );
