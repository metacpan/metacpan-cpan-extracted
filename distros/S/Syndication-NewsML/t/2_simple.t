#!/usr/bin/perl -w
use strict;
use Test;

use Syndication::NewsML;

my $TESTS;
BEGIN { 
#   require "t/TestDetails.pm"; import TestDetails;
   $TESTS = 8;
   plan tests => $TESTS; 
}

MAIN:
{
	my $filename = "t/test_data/sportsresult.xml";
	my $newsml = new Syndication::NewsML($filename);
	my $env = $newsml->getNewsEnvelope;
	# test 1: envelope exists
	ok(defined($env));

	# test 2: dateAndTime is what we expect it to be
	ok($env->getDateAndTime->getText, "20001006");

	# test 3: news item count is what we expect it to be
	ok($newsml->getNewsItemCount, 1);

	# we know this loop will only be executed once
	my $nitems = $newsml->getNewsItemList;

	# only one news item in this example
	my $nitem = $nitems->[0];

	# test 4: news item type is what we expect it to be
	ok($nitem->getType, "NewsComponent");

	my $comp = $nitem->getNewsComponent;

	# test 5: news component exists 
	ok(defined($comp));

	# test 6: content item count is what it should be
	my $count = $comp->getContentItemCount;
	ok($comp->getContentItemCount, 1);

	my $citems = $comp->getContentItemList;

	# only one content item in this example
	my $citem = $citems->[0];

	# should have a DataContent element
	my $datacontent = $citem->getDataContent;

	# test 7: data content exists
	ok(defined($datacontent));

	# get the contents as a node
	my $data = $datacontent->getText;

	# test 8: check that data text contains a string (simple test, this is actually an XML string)
	ok($data, qr/Arsenal/);
}
