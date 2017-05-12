#!/usr/bin/perl -w
use strict;
use Test;

use Syndication::NITF;

my $TESTS;
BEGIN { 
   $TESTS = 24;
   plan tests => $TESTS; 
}

MAIN:
{
	my $filename = "t/test_data/nitf-fishing.xml";
	my $nitf = new Syndication::NITF($filename);
	my $head = $nitf->gethead;
	# test 1: head exists
	ok(defined($head));

	# test 2: dateAndTime is what we expect it to be
	ok($head->gettitle->getText, "Norfolk Weather and Tide Updates");

	my $tobject = $head->gettobject;

	# test 3: tobject type is what we expect it to be
	ok($tobject->gettobjecttype, "news");

	# test 4: tobject.subject count is what we expect it to be
	ok($tobject->gettobjectsubjectCount, 2);

	# test 5: ref num of first component is what we want
	ok($tobject->gettobjectsubjectList->[0]->gettobjectsubjectrefnum, "17000000");

	# test 6: type of first component is what we want
	ok($tobject->gettobjectsubjectList->[0]->gettobjectsubjecttype, "Weather");

	# test 7: ref num of second component is what we want
	ok($tobject->gettobjectsubjectList->[1]->gettobjectsubjectrefnum, "04001002");

	# test 8: detail of second component is what we want
	ok($tobject->gettobjectsubjectList->[1]->gettobjectsubjectdetail, "Fishing Industry");

	my $docdata = $head->getdocdata;

	# test 9: location code
	ok($docdata->getidentifiedcontentList->[0]->getlocationList->[0]->getlocationcode, "23602");

	# test 10: code source
	ok($docdata->getidentifiedcontentList->[0]->getlocationList->[0]->getcodesource, "zipcodes.usps.gov");

	my $body = $nitf->getbody;

	my $bodyhead = $body->getbodyhead;

	# test 11: "hedline" hl1
	ok($bodyhead->gethedline->gethl1->getText, "Weather and Tide Updates for Norfolk");

	# test 12: "hedline" hl2 (is a list)
	ok($bodyhead->gethedline->gethl2List->[0]->getText, "A sample, fictitious NITF article");

	# test 13: header note
	ok($bodyhead->getnoteList->[0]->getbodycontentList->[0]->getpList->[0]->getText, qr/somewhat contrived/);

	# test 14: byline person
	ok($bodyhead->getbylineList->[0]->getpersonList->[0]->getText, "Alan Karben");

	# test 15: byline byttl "byline title" including organisation
	ok($bodyhead->getbylineList->[0]->getbyttlList->[0]->getText, "NITF Network News Online");

	my $bodycontent = $body->getbodycontentList->[0];

	# test 16: test getText grabbing contents of child elements
	ok($bodycontent->getpList->[0]->getText("strip"), qr/by the Acme/);
	
	# test 17: test getXML, returning entire element and all children as XML
	ok($bodycontent->getpList->[0]->getXML, qr/by the <org value="acm"/);

	### need to do smarter things with the body text...	

	my $nitftable = $bodycontent->getnitftableList->[0];

	# test 18: test nitf-table-summary
	ok($nitftable->getnitftablemetadata->getnitftablesummary->getpList->[0]->getText, qr/Norfolk, Virginia/);

	# test 19: test nitf-table-metadata
	ok($nitftable->getnitftablemetadata->getnitfcolList->[0]->getvalue, "beach");

	# test 20: test nitf-table-metadata
	ok($nitftable->getnitftablemetadata->getnitfcolList->[1]->getvalue, "day-high");

	# test 21: test nitf-table-metadata
	ok($nitftable->getnitftablemetadata->getnitfcolList->[2]->getvalue, "day-low");

	# test 22: test nitf-table-metadata
	ok($nitftable->getnitftablemetadata->getnitfcolList->[3]->getvalue, "tide-time");

	# test 23: test nitf-table-metadata
	ok($nitftable->getnitftablemetadata->getnitfcolList->[3]->getoccurrences, "2");

	# test 24: test nitf-table-metadata
	ok($nitftable->getnitftablemetadata->getnitfcolgroupList->[0]->getoccurrences, "3");

}
