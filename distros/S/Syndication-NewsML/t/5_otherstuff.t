#!/usr/bin/perl -w
use strict;
use Test;

use Syndication::NewsML;

my $TESTS;
BEGIN { 
#   require "t/TestDetails.pm"; import TestDetails;
   $TESTS = 3;
   plan tests => $TESTS; 
}

MAIN:
{
	my $filename = "t/test_data/sportsresult.xml";
	my $newsml = new Syndication::NewsML($filename);
	my $env = $newsml->getNewsEnvelope;
	# test 1: envelope exists
	ok(defined($env));

	# test 2: tag name works
	ok($env->getTagName, "NewsEnvelope");

	# test 3: getPath works
	my $deepnode = $newsml->getNewsItemList->[0]->getIdentification->getNewsIdentifier->getProviderId;

	ok($deepnode->getPath, "NewsML->NewsItem->Identification->NewsIdentifier->ProviderId");
}
