#!perl -T
# should have used or not !perl -T?
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 5;

BEGIN {
    use_ok( 'Photonic' ) || print "Bail out!\n";
}

BEGIN {
    use_ok( 'Photonic::CharacteristicFunctions' ) || print "Bail out!\n";
}
    
BEGIN {
    use_ok( 'Photonic::Geometry' ) || print "Bail out!\n";
}
    

BEGIN { 
    use_ok( 'Photonic::Geometry::FromImage2D' ) || print "Bail out!\n";
}

    
BEGIN {
    use_ok( 'Photonic::ExtraUtils' ) || print "Bail out!\n";
}

diag( "Testing Photonic $Photonic::VERSION, Perl $], $^X" );
