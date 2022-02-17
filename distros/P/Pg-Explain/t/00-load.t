#!perl

use Test::More tests => 13;

BEGIN {
    use_ok( 'Pg::Explain' );
    use_ok( 'Pg::Explain::Analyzer' );
    use_ok( 'Pg::Explain::Hinter' );
    use_ok( 'Pg::Explain::Hinter::Hint' );
    use_ok( 'Pg::Explain::Buffers' );
    use_ok( 'Pg::Explain::FromJSON' );
    use_ok( 'Pg::Explain::FromText' );
    use_ok( 'Pg::Explain::FromXML' );
    use_ok( 'Pg::Explain::FromYAML' );
    use_ok( 'Pg::Explain::From' );
    use_ok( 'Pg::Explain::JIT' );
    use_ok( 'Pg::Explain::Node' );
    use_ok( 'Pg::Explain::StringAnonymizer' );
}

diag( "Testing Pg::Explain $Pg::Explain::VERSION, Perl $], $^X" );
