#!/usr/bin/perl -w
use strict;
use Test;

use Syndication::NewsML;

my $TESTS;
BEGIN { 
#   require "t/TestDetails.pm"; import TestDetails;
   $TESTS = 86;
   plan tests => $TESTS
}

MAIN:
{
	my $filename = "t/test_data/mlking.xml";
	my $newsml = new Syndication::NewsML($filename);

	# test 1: could open and read file
	ok($newsml);

	## test Catalog element and children

	my $catalog = $newsml->getCatalog;

	# test 2: catalog exists
	ok(defined($catalog));

	# test 3: number of resources matches what we think
	ok($catalog->getResourceCount, 27);

	# should we introduce a getResourceNo(20) type method?
	my $resource= $catalog->getResourceList->[20];

	# test 4: resource URN matches what we think
	ok($resource->getUrn->getText, "urn:newsml:iptc.org:20001006:topicset.iptc-topictype:1");
	
	# test 5: resource URL matches what we think
	ok($resource->getUrlList->[0]->getText, "./topicsets/iptc-topictype.xml");

	# TODO
#	ok($resource->getReferencedUrl); # or something like that to load the file

	my $defaultvocab= $resource->getDefaultVocabularyForList->[0];

	# test 6: test "scheme" of default vocabulary type
	ok($defaultvocab->getScheme, "IptcTopicType");

	# test 7: test "context" of default vocabulary type
	ok($defaultvocab->getContext, "TopicType");

	## test TopicSet element and children

	my $topicset = $newsml->getTopicSetList->[0];

	# test 8: Duid of the document's TopicSet
	ok($topicset->getDuid, "iptc.status");

	# test 9: FormalName of the document's TopicSet
	ok($topicset->getFormalName, "Status");

	my $comment = $topicset->getCommentList->[0];

	# test 10: language of the comment
	ok($comment->getXmlLang, "en");

	# test 11: language of the comment
	ok($comment->getText, qr/usability/);

	my $topic = $topicset->getTopicList->[2];

	# test 12: Duid of the topic
	ok($topic->getDuid, "stat3");

	# test 13: TopicType:Scheme
	ok($topic->getTopicTypeList->[0]->getScheme, "IptcTopicType");

	# test 14: TopicType:FormalName
	ok($topic->getTopicTypeList->[0]->getFormalName, "Status");

	# test 15: FormalName:Scheme
	ok($topic->getFormalNameList->[0]->getScheme, "IptcStatus");

	# test 16: FormalName:Text
	ok($topic->getFormalNameList->[0]->getText, "Withheld");

	## test NewsEnvelope element and children

	my $env = $newsml->getNewsEnvelope;

	# test 17: Envelope exists
	ok(defined($env));

	# test 18: DateAndTime is what we think it should be
	ok($env->getDateAndTime->getText, "20000717T160000");

	## test NewsItem element and children (the main guts of the document)

	# test 19: right number of NewsItems
	ok($newsml->getNewsItemCount, 1);

	my $newsitem = $newsml->getNewsItemList->[0];

	# test 20: NewsItem exists
	ok(defined($newsitem));

	# test 21: NewsItem's Duid is what we think it should be
	ok($newsitem->getDuid, "Crts");

	my $identification = $newsitem->getIdentification;
	
	# test 22: NewsItem's Identifier's ProviderId is what we think it should be
	ok($identification->getNewsIdentifier->getProviderId->getText, "iptc.org");
	
	# test 23: NewsItem's Identifier's DateId is what we think it should be
	ok($identification->getNewsIdentifier->getDateId->getText, "20000717");

	# test 24: NewsItem's Identifier's NewsItemId is what we think it should be
	ok($identification->getNewsIdentifier->getNewsItemId->getText, "LutherKing");

	# test 25: NewsItem's Identifier's PublicIdentifier is what we think it should be
	ok($identification->getNewsIdentifier->getPublicIdentifier->getText,
		"urn:newsml:iptc.org:20000717:LutherKing:1");

	## test NewsManagement element and children (which is still part of the NewsItem)
	
	my $newsmanagement = $newsitem->getNewsManagement;

	# test 26: NewsManagement's NewsItemType's FormalName is what we think it should be
	ok($newsmanagement->getNewsItemType->getFormalName, "News");

	# test 27: NewsManagement's NewsItemType's Scheme is what we think it should be
	ok($newsmanagement->getNewsItemType->getScheme, "IptcNewsItemType");

	# test 28: NewsManagement's FirstCreated tag is what we think it should be
	ok($newsmanagement->getFirstCreated->getText, "20000720T100000");

	# test 29: NewsManagement's ThisRevisionCreated tag is what we think it should be
	ok($newsmanagement->getThisRevisionCreated->getText, "20000720T100000");

	# test 30: NewsManagement's Status's FormalName attr is what we think it should be
	ok($newsmanagement->getStatus->getFormalName, "Usable");

	# test 31: NewsManagement's Status's Vocabulary attr is what we think it should be
	ok($newsmanagement->getStatus->getVocabulary, "#iptc.status");

	# check out the related topicset of this vocabulary.
	# this is a tricky one, it looks up the relevant topicset for #iptc.status and finds
	# the comment field from inside.

	# test 32: get the description of the referenced topicset for this status node.
	ok($newsmanagement->getStatus->resolveTopicSetDescription, "The current usability of a NewsItem.");

	# test 33: NewsManagement's Status's Scheme attr is what we think it should be
	ok($newsmanagement->getStatus->getScheme, "IptcStatus");

	## test NewsComponent element and children (which is still part of the NewsItem)
	
	my $newscomponent = $newsitem->getNewsComponent;

	# test 34: NewsComponent's Duid attr is what we think it should be
	ok($newscomponent->getDuid, "Mlkc1");

	# test 35: NewsComponent's Catalog's Resource's Urn is what we think it should be
	ok($newscomponent->getCatalog->getResourceList->[0]->getUrn->getText, "iptc.subject");

	# test 36: NewsComponent's Catalog's Resource's Url is what we think it should be
	ok($newscomponent->getCatalog->getResourceList->[0]->getUrlList->[0]->getText, "./topicsets/iptc-subjectcode.xml");

	# test 37: NewsComponent's Catalog's Resource's DefaultVocabularyFor's Context attr is what we think it should be
	ok($newscomponent->getCatalog->getResourceList->[0]->getDefaultVocabularyForList->[0]->getContext,
		"SubjectMatter");

	# test 38: NewsComponent's Role's FormalName attr is what we think it should be
	ok($newscomponent->getRole->getFormalName, "Main");

	# test 39: NewsComponent's Role's Scheme attr is what we think it should be
	ok($newscomponent->getRole->getScheme, "IptcRole");

	# test 40: NewsComponent's NewsLines's HeadLine element is what we think it should be
	ok($newscomponent->getNewsLines->getHeadLineList->[0]->getText, "Civil Rights");

	my $subjectmatter = $newscomponent->getDescriptiveMetadata->getSubjectCodeList->[0]->getSubjectMatterList;
	# test 41
	ok($subjectmatter->[0]->getScheme, "IptcSubjectCodes");

	# test 42
	ok($subjectmatter->[0]->getFormalName, "11007000");

	# test 43
	ok($subjectmatter->[1]->getScheme, "IptcSubjectCodes");

	# test 44
	ok($subjectmatter->[1]->getFormalName, "14014000");

	# test 45
	ok($subjectmatter->[2]->getScheme, "IptcSubjectCodes");

	# test 46
	ok($subjectmatter->[2]->getFormalName, "12002000");

	# test 47
	ok($subjectmatter->[3]->getScheme, "IptcSubjectCodes");

	# test 48
	ok($subjectmatter->[3]->getFormalName, "16003000");

	## now go through news components

	my $newscomp1 = $newscomponent->getNewsComponentList->[0];

	# test 49
	ok($newscomp1->getDuid, "Compa");

	# test 50
	ok($newscomp1->getRole->getFormalName, "Supporting");

	# test 51
	ok($newscomp1->getRole->getScheme, "IptcRole");

	my $contentitem1 = $newscomp1->getContentItemList->[0];

	# test 52
	ok($contentitem1->getHref, "../examples/civilrt.xml");

	# test 53
	ok($contentitem1->getCommentList->[0]->getText, "Intro");

	# test 54
	ok($contentitem1->getMimeType->getFormalName, "text/xml");

	# test 55
	ok($contentitem1->getMimeType->getScheme, "IptcMimeTypes");

	my $newscomp2 = $newscomponent->getNewsComponentList->[1];

	# test 56
	ok($newscomp2->getDuid, "Compb");

	# test 57
	ok($newscomp2->getRole->getFormalName, "Supporting");

	# test 58
	ok($newscomp2->getRole->getScheme, "IptcRole");

	my $contentitem2 = $newscomp2->getContentItemList->[0];

	# test 59
	ok($contentitem2->getHref, "../examples/mlking.jpg");

	# test 60
	ok($contentitem2->getCommentList->[0]->getText, "Photo");

	# test 61
	ok($contentitem2->getMimeType->getFormalName, "image/jpeg");

	# test 62
	ok($contentitem2->getMimeType->getScheme, "IptcMimeTypes");

	my $newscomp3 = $newscomponent->getNewsComponentList->[2];

	# test 63
	ok($newscomp3->getDuid, "Compc");

	# test 64
	ok($newscomp3->getEquivalentsList, "yes");

	# test 65
	ok($newscomp3->getRole->getFormalName, "Supporting");

	# test 66
	ok($newscomp3->getRole->getScheme, "IptcRole");

	# test 67
	ok($newscomp3->getBasisForChoiceList->[0]->getText, "MediaType");

	my $contentitem31 = $newscomp3->getContentItemList->[0];

	# test 68
	ok($contentitem31->getHref, "../examples/ihada.xml");

	# test 69
	ok($contentitem31->getCommentList->[0]->getText, "Speech text");

	# test 70
	ok($contentitem31->getMediaType->getFormalName, "Text");

	# test 71
	ok($contentitem31->getMediaType->getScheme, "IptcMediaTypes");

	# test 72
	ok($contentitem31->getMimeType->getFormalName, "text/xml");

	# test 73
	ok($contentitem31->getMimeType->getScheme, "IptcMimeTypes");

	my $contentitem32 = $newscomp3->getContentItemList->[1];

	# test 74
	ok($contentitem32->getHref, "../examples/luther.wav");

	# test 75
	ok($contentitem32->getCommentList->[0]->getText, "Sound recording");

	# test 76
	ok($contentitem32->getMediaType->getFormalName, "Audio");

	# test 77
	ok($contentitem32->getMediaType->getScheme, "IptcMediaTypes");

	# test 78
	ok($contentitem32->getMimeType->getFormalName, "audio/x-wav");

	# test 79
	ok($contentitem32->getMimeType->getScheme, "IptcMimeTypes");

	my $newscomp4 = $newscomponent->getNewsComponentList->[3];

	# test 80
	ok($newscomp4->getDuid, "Compd");

	# test 81
	ok($newscomp4->getEquivalentsList, "no");

	# test 82
	ok($newscomp4->getRole->getFormalName, "Supplementary");

	# test 83
	ok($newscomp4->getRole->getScheme, "IptcRole");

	my $newsitemref = $newscomp4->getNewsItemRefList->[0];

	# test 84
	ok(defined($newsitemref));

	# test 85
	ok($newsitemref->getNewsItem, "../topicsets/topicset.iptc-genre.xml");

	# test 86
	ok($newsitemref->getCommentList->[0]->getText, "An example TopicSet");
}
