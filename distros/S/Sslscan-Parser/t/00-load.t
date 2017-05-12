#!perl -T

use Test::More tests => 6;
BEGIN {
    use_ok( 'Sslscan::Parser' );
    use_ok( 'Sslscan::Parser::Host' );
    use_ok( 'Sslscan::Parser::Host::Port' );
    use_ok( 'Sslscan::Parser::Host::Port::Cipher' );
    use_ok( 'Sslscan::Parser::Session' );
    use_ok( 'Sslscan::Parser::ScanDetails' );
}

