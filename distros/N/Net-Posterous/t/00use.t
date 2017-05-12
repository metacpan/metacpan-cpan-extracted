#!perl -T

use Test::More tests => 6;

BEGIN {
        use_ok( 'Net::Posterous' );
        use_ok( 'Net::Posterous::Site' );
        use_ok( 'Net::Posterous::Post' );
        use_ok( 'Net::Posterous::Media' );
        use_ok( 'Net::Posterous::Comment' );
        use_ok( 'Net::Posterous::Tag' );

}

diag( "Testing Net::Posterous $Net::Posterous::VERSION, Perl $], $^X" );
