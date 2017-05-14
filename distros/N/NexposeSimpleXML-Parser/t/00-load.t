#!perl -T

use Test::More tests => 8;
BEGIN {
    use_ok( 'NexposeSimpleXML::Parser' );
    use_ok( 'NexposeSimpleXML::Parser::Host' );
    use_ok( 'NexposeSimpleXML::Parser::Host::Service' );
    use_ok( 'NexposeSimpleXML::Parser::Session' );
    use_ok( 'NexposeSimpleXML::Parser::ScanDetails' );
    use_ok( 'NexposeSimpleXML::Parser::Fingerprint' );
    use_ok( 'NexposeSimpleXML::Parser::Vulnerability' );
    use_ok( 'NexposeSimpleXML::Parser::Reference' );

}

