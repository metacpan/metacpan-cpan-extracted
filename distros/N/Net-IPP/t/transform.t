###
# Copyright (c) 2004 Matthias Hilbig <bighil@cpan.org>
# All rights reserved.
# 
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
#
# 
# Testcases for the transformValue method:
#
# encode and decode some test values and look
# if the resulting value is the same as some 
# expected value
#

use Test::More tests => 22;
BEGIN { use_ok('Net::IPP::IPPRequest');
use_ok('Net::IPP::IPPAttribute');
use_ok('Net::IPP::IPPUtil');
use_ok('Net::IPP::IPP', qw(:all));
};

use strict;

my $value = 12345;
testTransform($value, &INTEGER, 12345);
$value = -1;
testTransform($value, &INTEGER, 4294967295);
$value = 3456;
testTransform($value, &ENUM, 3456);

$value = "";
testTransform($value, &BOOLEAN, 0);
$value = "true";
testTransform($value, &BOOLEAN, 1);
$value = -1;
testTransform($value, &BOOLEAN, 1);
$value = 0;
testTransform($value, &BOOLEAN, 0);
$value = 1;
testTransform($value, &BOOLEAN, 1);

$value = "hötzel";
testTransform($value, &OCTET_STRING, "hötzel");

$value = "12-10-2004,12:23:34.99,-1:0";
testTransform($value, &DATE_TIME, "12-10-2004,12:23:34.99,-1:0");
$value = " 12 - 10 - 2004 ,  012 : 023 : 034 . 0099 , - 001 : 00 ";
testTransform($value, &DATE_TIME, "12-10-2004,12:23:34.99,-1:0");
# the next value can not be parsed as date
$value = " 12 - 10 - 2004 :  012 : 023 : 034 . 0099 , - 001 : 00 ";
testTransform($value, &DATE_TIME, "0-0-0,0:0:0.0,+0:0");

$value = "300, 600 dpi";
testTransform($value, &RESOLUTION, "300, 600 dpi");
$value = "600,1200dpc";
testTransform($value, &RESOLUTION, "600, 1200 dpc");

$value = " 1 : 1000 ";
testTransform($value, &RANGE_OF_INTEGER, "1:1000");

$value = "en, text";
testTransform($value, &TEXT_WITH_LANGUAGE, "en, text");
$value = " en ,text ";
testTransform($value, &TEXT_WITH_LANGUAGE, "en, text");
$value = "en,text";
testTransform($value, &TEXT_WITH_LANGUAGE, "en, text");


###
# Encode and decode value, outputs ERROR if decoded value does not equal
# the expected value.
#
# parameters: $value         - value to encode and decode
#             $type          - IPP type to use
#             $expectedValue - value to expect after encoding and decoding
#
sub testTransform {
	my $value = shift;
	my $type = shift;
	my $expectedValue = shift;
	
	print("\nTestvalue: $value, Type: $type\n"); 
	
	my $bytes = Net::IPP::IPPAttribute::transformValue($type, "bogus-name", $value, 0);
	print "Encoded value: ";
	Net::IPP::IPPUtil::printBytes($bytes);
	my $newValue = Net::IPP::IPPAttribute::transformValue($type, "bogus-name", $bytes, 1);

	is ($expectedValue, $newValue);

}
