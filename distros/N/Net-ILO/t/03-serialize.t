#!perl

use strict;

use Net::ILO;
use Test::More tests => 4;

my $xml_good = qq|
    <?xml version="1.0"?>
    <RIBCL VERSION="2.22">
        <RESPONSE
            STATUS="0x0000"
            MESSAGE='No error'
        />
    </RIBCL>
    <?xml version="1.0"?>
    <RIBCL VERSION="2.22">
        <RESPONSE
            STATUS="0x0000"
            MESSAGE='No error'
        />
    </RIBCL>
    <?xml version="1.0"?>
    <RIBCL VERSION="2.22">
        <RESPONSE
            STATUS="0x0000"
            MESSAGE='No error'
        />
        <GET_GLOBAL_SETTINGS>
            <TEST_ITEM VALUE="30"/>
        </GET_GLOBAL_SETTINGS>
    </RIBCL>
|;

my $xml_bad = qq|
    <?xml version="1.0"?>
    <RIBCL VERSION="2.22">
|;

my $xml_empty = qq||;


my $ilo = Net::ILO->new;

my $parsed_good  = $ilo->_serialize($xml_good);

my $parsed_bad   = $ilo->_serialize($xml_bad);
my $error_bad    = $ilo->error;

my $parsed_empty = $ilo->_serialize($xml_empty);
my $error_empty  = $ilo->error;

ok( $parsed_good->{GET_GLOBAL_SETTINGS}->{TEST_ITEM}->{VALUE} == 30, 'XML parsed correctly' );
ok( !$parsed_bad,                                                    'Bad XML sent to parser returns false' );
ok( !$parsed_empty,                                                  'Null data sent to parser returns false' );
ok( $error_empty eq 'Error parsing response: no data received',      'Error message set for null data');

