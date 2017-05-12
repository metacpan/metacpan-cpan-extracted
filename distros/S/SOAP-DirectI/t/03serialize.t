#
#===============================================================================
#
#         FILE:  02parse.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  06.04.2009 04:30:02 MSD
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 1;                      # last test to print

use SOAP::DirectI::Serialize;

my $me = SOAP::DirectI::Serialize->hash_to_soap( 
    {
	test_me_right_now => [ 10 ],
	test_me_right_now_hash => {
	    'there&there' => 10,
	    there_there => 20,
	},
	complex_hash => {
	    there => {
		test => 20
	    },
	},
    }, 
    {
	name => 'testAnswer',
	args =>
	[
	    {
		key	    => 'testMeRightNow',
		type	    => 'array',
		elem_type   => 'boolean',
	    },
	    {
		key	    => 'testMeRightNowHash',
		type	    => 'map',
		key_type    => 'string',
		value_type  => 'int',
	    },
	    {
		key	    => 'complexHash',
		type	    => 'map',
		key_type    => 'string',
		value_sig   => {
		    type => 'map',
		    key  => 'value',
		    key_type => 'string',
		    value_type => 'int',
		},
	    }
	],
    },
);

$me =~ tr/ //d;

my $reference ='<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:si="http://soapinterop.org/xsd" xmlns:apachesoap="http://xml.apache.org/xml-soap" xmlns:impl="com.logicboxes.foundation.sfnb.user.Customer">
   <SOAP-ENV:Body>
	 <impl:testAnswer>
<testMeRightNow xsi:type="SOAP-ENC:Array" SOAP-ENC:arrayType="xsd:boolean[1]"><item xsi:type="xsd:boolean">true</item></testMeRightNow><testMeRightNowHash xsi:type="apachesoap:Map"><item><key xsi:type="xsd:string">there&amp;there</key><value xsi:type="xsd:int">10</value></item><item><key xsi:type="xsd:string">there_there</key><value xsi:type="xsd:int">20</value></item></testMeRightNowHash><complexHash xsi:type="apachesoap:Map"><item><key xsi:type="xsd:string">there</key><value xsi:type="apachesoap:Map"><item><key xsi:type="xsd:string">test</key><value xsi:type="xsd:int">20</value></item></value></item></complexHash>

	</impl:testAnswer>
    </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
';

$reference =~ tr/ //d;

is( $me, $reference );
