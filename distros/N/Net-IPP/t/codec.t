###
# Copyright (c) 2004 Matthias Hilbig <bighil@cpan.org>
# All rights reserved.
# 
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
#
#
# Testcases for the encode/decode method:
#
# encode an IPP request, decode it and look if
# the result is the same as the original request.
#

use Test::More tests => 5;
BEGIN { 
use_ok('Net::IPP::IPPRequest'); 
use_ok('Net::IPP::IPP',qw(:all));
use_ok('Net::IPP::IPPUtil'); 
};

use strict;

print "*********************TEST 1************************\n";
my $request = {
    &URL => "ipp://fobar/",
    &REQUEST_ID => 1,
    &OPERATION => &IPP_GET_PRINTER_ATTRIBUTES,
    &GROUPS => [
    		{
    			&TYPE => &OPERATION_ATTRIBUTES,
    			"attributes-charset" => "utf-8",
    			"attributes-natural-language" => "en",
    			"printer-uri" => "ipp://fobar/",
			"job-uri" => "", #test empty attribute
    		},
    		{
    			&TYPE => &JOB_ATTRIBUTES,
    		} # empty group
    	]
    };
testCoding($request);

print "\n*********************TEST 2************************\n";
$request = {
    &URL => "ipp://fobar/",
    &REQUEST_ID => 1,
    &OPERATION => &IPP_GET_PRINTER_ATTRIBUTES,
    &GROUPS => [
    		{
    			&TYPE => &OPERATION_ATTRIBUTES,
    			"attributes-charset" => "utf-8",
    			"attributes-natural-language" => "en",
    			"printer-uri" => "ipp://fobar/",
    		},
    		{
    			&TYPE => &JOB_ATTRIBUTES,
    			"test1" => {&TYPE => &INTEGER,
    				    &VALUE => [3, 4, 5, 6, 7, 8, 9]},
    			"media" => ["test","test1","test2"],
    		}
    	]
    };
testCoding($request);

###
#
#
sub testCoding {
	my $request = shift;
	
	my $before = Net::IPP::IPPUtil::ippToString($request);
	
	print "\nIPP Request BEFORE:\n$before";

	my $bytes = Net::IPP::IPPRequest::hashToBytes($request);

	print "\nEncoded Request:\n";
	Net::IPP::IPPUtil::printBytes($bytes);

	my $response = {};
	$response = Net::IPP::IPPRequest::bytesToHash($bytes, $response);
	
	my $after = Net::IPP::IPPUtil::ippToString($response);
	
	print "\nIPP Request AFTERWARDS:\n$after";
	

	$before =~ s/^.*?GROUP/GROUP/s;
	$after =~ s/^.*?GROUP/GROUP/s;
		

	is($before, $after);
}

