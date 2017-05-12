#!perl -T

use Test::More tests => 6;
BEGIN {
    use_ok( 'Nikto::Parser' );
    use_ok( 'Nikto::Parser::Host' );
    use_ok( 'Nikto::Parser::Host::Port' );
    use_ok( 'Nikto::Parser::Host::Port::Item' );
    use_ok( 'Nikto::Parser::Session' );
    use_ok( 'Nikto::Parser::ScanDetails' );

}

