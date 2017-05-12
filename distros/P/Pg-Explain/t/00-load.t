#!perl

use Test::More tests => 8;

BEGIN {
    use_ok( 'Pg::Explain' );
    use_ok( 'Pg::Explain::From' );
    use_ok( 'Pg::Explain::FromJSON' );
    use_ok( 'Pg::Explain::FromText' );
    use_ok( 'Pg::Explain::FromXML' );
    use_ok( 'Pg::Explain::FromYAML' );
    use_ok( 'Pg::Explain::Node' );
    use_ok( 'Pg::Explain::StringAnonymizer' );
}

diag( "Testing Pg::Explain $Pg::Explain::VERSION, Perl $], $^X" );
