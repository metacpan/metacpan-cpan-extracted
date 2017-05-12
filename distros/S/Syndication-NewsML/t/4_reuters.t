#!/usr/bin/perl -w
use strict;
use Test;

use Syndication::NewsML;

my $TESTS;
BEGIN { 
#   require "t/TestDetails.pm"; import TestDetails;
   $TESTS = 72;
   plan tests => $TESTS; 
}

MAIN:
{
	my $filename = "t/test_data/reuters-test.xml";
	my $newsml = new Syndication::NewsML($filename);

	# test 1: could open and read file
	ok($newsml);

	my $catalog = $newsml->getCatalog;

	# test 2: catalog exists
	ok(defined($catalog));

	# test 3: number of resources matches what we think
	ok($catalog->getResourceCount, 13);

	my $resource = $catalog->getResourceList->[2];

	# test 4
	ok($resource->getUrlList->[0]->getText, "http://www.reuters.com/ids/vocabularies/ids/destination.xml");

	# test 5
	ok($resource->getDefaultVocabularyForList->[0]->getContext, "NewsService");

	my $newsenvelope = $newsml->getNewsEnvelope;

	# test 6
	ok($newsenvelope->getDateAndTime->getText, "20010907T151305+0000");

	# test 7
	ok($newsenvelope->getNewsServiceList->[0]->getFormalName, "OUWDPLUS");

	# test 8
	ok($newsenvelope->getPriority->getFormalName, "4");

	my $newsitem = $newsml->getNewsItemList->[0];

	my $identifier = $newsitem->getIdentification->getNewsIdentifier;

	# test 9
	ok($identifier->getProviderId->getText, "Reuters.Com");

	# test 10
	ok($identifier->getDateId->getText, "20010907");

	# test 11
	ok($identifier->getNewsItemId->getText, "ID00301");

	# test 12
	ok($identifier->getRevisionId->getPreviousRevision, "0");

	# test 13
	ok($identifier->getRevisionId->getUpdate, "N");

	# test 14
	ok($identifier->getRevisionId->getText, "1");

	# test 15
	ok($identifier->getPublicIdentifier->getText, "urn:newsml:Reuters.Com:20010907:ID00301:1");

	my $newsmanagement = $newsitem->getNewsManagement;

	# test 16
	ok($newsmanagement->getNewsItemType->getFormalName, "News");

	# test 17
	ok($newsmanagement->getFirstCreated->getText, "20010907T151305+0000");

	# test 18 -- Perl time test
	ok($newsmanagement->getFirstCreated->getDatePerl, 999875585);

	# test 19
	ok($newsmanagement->getThisRevisionCreated->getText, "20010907T151305+0000");

	# test 20
	ok($newsmanagement->getStatus->getFormalName, "Usable");

	# test 21
	ok($newsmanagement->getUrgency->getFormalName, "4");

	my $newscomponent = $newsitem->getNewsComponent;

	# test 22
	ok($newscomponent->getEquivalentsList, "no");

	my $resource2 = $newscomponent->getCatalog->getResourceList->[0];

	# test 23
	ok($resource2->getUrlList->[0]->getText, "http://www.reuters.com/ids/vocabularies/topictypes.xml");

	# test 24
	ok($resource2->getDefaultVocabularyForList->[0]->getContext, 'TopicSet/@FormalName');

	my $topicset = $newscomponent->getTopicSetList->[0];

	# test 25
	ok($topicset->getFormalName, "companies");

	my $resource3 = $topicset->getCatalog->getResourceList->[0];

	# test 26
	ok($resource3->getUrlList->[0]->getText, "http://www.reuters.com/ids/vocabularies/nasdaqvocab.xml");

	# test 27
	ok($resource3->getDefaultVocabularyForList->[0]->getContext, 'Topic/TopicType/@FormalName');

	my $topic = $topicset->getTopicList->[0];

	# test 28
	ok($topic->getDetails, "www.reuters.com");

	# test 29
	ok($topic->getDuid, "company1");

	# test 30
	ok($topic->getTopicTypeList->[0]->getFormalName, "company");

	# test 31
	ok($topic->getFormalNameList->[0]->getScheme, "ric");

	# test 32
	ok($topic->getFormalNameList->[0]->getText, "RTRSY.O");

	# test 33
	ok($topic->getFormalNameList->[1]->getScheme, "nasdticker");

	# test 34
	ok($topic->getFormalNameList->[1]->getText, "RTRSY");

	# test 35
	ok($topic->getFormalNameList->[2]->getScheme, "companyshortname");

	# test 36
	ok($topic->getFormalNameList->[2]->getText, "Reuters");

	# test 37
	ok($topic->getDescriptionList->[0]->getVariant, "fullcompanyname");

	# test 38
	ok($topic->getDescriptionList->[0]->getText, "REUTERS PLC");

	# test 39
	ok($newscomponent->getRole->getFormalName, "SUPER_LINKED_LIST");

	my $newslines = $newscomponent->getNewsLines;

	# test 40
	ok($newslines->getHeadLineList->[0]->getText, "SLL-SHOWCASE");

	# test 41
	ok($newslines->getByLineList->[0]->getText, "");

	# test 42
	ok($newslines->getDateLineList->[0]->getText, "20010907");

	# test 43
	ok($newslines->getCreditLineList->[0]->getText, "REUTERS");

	# test 44
	ok($newslines->getCopyrightLineList->[0]->getText, qr/Reuters Limited/);

	# test 45
	ok($newslines->getSlugLineList->[0]->getText, "OUWDPLUS-SUPER-LINK");

	# test 46
	ok($newslines->getNewsLineList->[0]->getNewsLineType->getFormalName, "caption");

	# test 47
	ok($newslines->getNewsLineList->[0]->getNewsLineTextList->[0]->getText, "Super Linked List");

	# test 48
	ok($newscomponent->getFileName, "");

	# test 49
	ok($newscomponent->getProvider->getDescriptionList->[0]->getText, "REUTERS PLC");

	# test 50
	ok($newscomponent->getCreator->getDescriptionList->[0]->getText, "REUTERS PLC");

	my $adminmeta = $newscomponent->getAdministrativeMetadata;

	my $rightsmeta = $newscomponent->getRightsMetadata;

	# test 51
	ok($newscomponent->getCopyrightHolder, "REUTERS PLC");

	# test 52
	ok($newscomponent->getCopyrightDate, "");

	# test 53
	ok($newscomponent->getLanguage, "en");

	my $newscomponent1 = $newscomponent->getNewsComponentList->[0];
	
	# test 54
	ok($newscomponent1->getRole->getFormalName, "NEWS_EVENT");

	# test 55
	ok($newscomponent1->getNewsLines->getHeadLineList->[0]->getText, "OUKWDPLUS-LUS-MICROSOFT-JUSTICE");

	# test 56
	ok($newscomponent1->getNewsLines->getSlugLineList->[0]->getText, "");

	# test 57
	ok($newscomponent1->getMetadataList->[0]->getMetadataType->getFormalName, "Order");

	# test 58
	ok($newscomponent1->getMetadataList->[0]->getPropertyList->[0]->getFormalName, "StoryOrder");

	# test 59
	ok($newscomponent1->getMetadataList->[0]->getPropertyList->[0]->getValue, "1");

	# they love nesting their newscomponents...
	my $newscomponent1_1 = $newscomponent1->getNewsComponentList->[0];

	# test 60
	ok($newscomponent1_1->getEquivalentsList, "no");

	# test 61
	ok($newscomponent1_1->getRole->getFormalName, "MAIN");

	# this is getting ridiculous!
	my $newscomponent1_1_1 = $newscomponent1_1->getNewsComponentList->[0];

	# test 62
	ok($newscomponent1_1_1->getEquivalentsList, "yes");

	# test 63
	ok($newscomponent1_1_1->getRole->getFormalName, "TEXT");

	# test 64
	ok($newscomponent1_1_1->getBasisForChoiceList->[0]->getText, '/@xml:lang');

	# test 65
	ok($newscomponent1_1_1->getMetadataList->[0]->getMetadataType->getFormalName, "Order");

	# test 66
	ok($newscomponent1_1_1->getMetadataList->[0]->getPropertyList->[0]->getFormalName, "ComponentNumber");

	# test 67
	ok($newscomponent1_1_1->getMetadataList->[0]->getPropertyList->[0]->getValue, "1");

	# lowest layer -- thank goodness!
	my $newscomponent1_1_1_1 = $newscomponent1_1_1->getNewsComponentList->[0];

	# test 68
	ok($newscomponent1_1_1_1->getEquivalentsList, "no"); # test out default

	# test 69
	ok($newscomponent1_1_1_1->getXmlLang, "en");

	# test 70
	ok($newscomponent1_1_1_1->getNewsLines->getHeadLineList->[0]->getText, qr/Microsoft/);
	
	# test 71
	ok($newscomponent1_1_1_1->getNewsLines->getSlugLineList->[0]->getText, qr/JUSTICE/);
	
	# test 72
	ok($newscomponent1_1_1_1->getNewsItemRefList->[0]->getNewsItem, "2001-09-07T084140Z_01_CAS731511_RTRIDST_0_OUKWDPLUS-LUS-MICROSOFT-JUSTICE.XML");
}
