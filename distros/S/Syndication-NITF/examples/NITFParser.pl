#!/usr/bin/perl

package NITFParser;

# not finished. It's still a good example of what you can do with the module, though.

use strict;
use NITF;

MAIN:
{
	my $filename = $ARGV[0] || die "Usage: $0 <filename to parse>\n";
	my $nitf = new Syndication::NITF($filename);
	my $head = $nitf->gethead;

	print "title is ".$head->gettitle->getText."\n";

	&parseTobject($head->gettobject);

	&parseDocData($head->getdocdata);

	my $body = $nitf->getbody;

	&parseBodyHead($body->getbodyhead);

	foreach my $bodycontent ($body->getbodycontentList) {
		&parseBodyContent($bodycontent);
	}

	&parseBodyEnd($body->getbodyend);
}

# "tobject" generally stores subject information about this document.
sub parseTobject {
	my ($tobject) = @_;

	print "Parsing tobject:\n";
	print "  tobject type: ".$tobject->gettobjecttype."\n";
	my $i = 1;
	foreach my $subject ($tobject->gettobjectsubjectList) {
		print "  subject ".$i.": ";
		# 1st tier description
		print $subject->gettobjectsubjecttype;
		print "/";
		# 2nd tier description
		print $subject->gettobjectsubjectmatter;
		print "/";
		# 3rd tier description
		print $subject->gettobjectsubjectdetail;
		# refnum conforms to IPTC subject codes, and gives more information than the type/matter/detail
		# on their own (ie the whole path rather than the node name)
		# so we will soon embed a copy of the IPTC subject codes and add some routines to handle them.
		print " (".$subject->gettobjectsubjectrefnum.")\n";
		# Is the IPR (info provider) the person who provides the subject codes or the
		# person who categorises the story? Defaults to "IPTC" so I guess it's the former
		my $ipr =  $subject->gettobjectsubjectipr;
		print "  info provider is ".$ipr."\n" if $ipr;
		$i++;
	}
}

# "docdata" contains general metadata about this document.
sub parseDocData {
	my ($docdata) = @_;

	print "Parsing docdata:\n";
	# docdata could contain one or more of:
	#  fixture --
	#  date.issue --
	#  date.release --
	#  date.expire --
	#  doc-scope --
	#  series --
	#  ed-msg --
	#  du-key --
	#  doc.copyright --
	#  doc.rights --
	#  key-list --
	#  identified-content (zero or more) --
	#  correction -- this story is a correction of another
	foreach my $correction ($docdata->getcorrectionList) {
		print "  Document is a correction\n";
		print "    This document's ID string is ".$correction->getidstring."\n";
		print "    It corrects document with ID ".$correction->getregsrc."\n";
		print "    Message: ".$correction->getinfo."\n";
	}
	#  evloc -- event location data
	foreach my $evloc ($docdata->getevlocList) {
		print "  Document event location data:\n";
		print "    City: ".$evloc->getcity."\n" if $evloc->getcity;
		print "    County/district: ".$evloc->getcountydist."\n" if $evloc->getcountydist;
		print "    ISO country code: ".$evloc->getisocc."\n" if $evloc->getisocc;
		print "    State/province: ".$evloc->getstateprov."\n" if $evloc->getstateprov;
	}
	#  doc-id -- document identification data
	foreach my $docid ($docdata->getdocidList) {
		print "  Document ID info:\n";
		print "    This document's ID string is ".$docid->getidstring."\n";
		print "    Source document ID is ".$docid->getregsrc."\n";
	}
	#  del-list -- delivery trail (like Path: in SMTP mail, I guess)
	foreach my $delitem ($docdata->getdellistList) {
		print "  Delivery list item:\n";
		print "    Level number is ".$delitem->getlevelnumber."\n" if $delitem->getlevelnumber;
		print "    Source name is ".$delitem->getsrcname."\n" if $delitem->getsrcname;
	}
	#  urgency -- importance of news item (1=most, 5=normal, 8=least)
	foreach my $urgency ($docdata->geturgencyList) {
		print "    Document urgency is ".$urgency->getedurg."\n";
	}
	#  fixture -- a named document which is refreshed periodically (eg a columnist)
	foreach my $fixture ($docdata->getfixtureList) {
		print "    Fixture ID is ".$fixture->getfixid."\n";
	}
	#  date.issue -- the date of issue of the document (default is date of receipt).
	foreach my $dateissue ($docdata->getdateissueList) {
		print "    Date of issue is ".$dateissue->getnorm."\n";
	}
	#  date.release -- the date/time that the document can be released (default is date of receipt).
	foreach my $daterelease ($docdata->getdatereleaseList) {
		print "    Release (embargo) date is ".$daterelease->getnorm."\n";
	}
	#  date.expire -- the date/time at which the story expires (default is infinity).
	foreach my $dateexpire ($docdata->getdateexpireList) {
		print "    Expiry date is ".$dateexpire->getnorm."\n";
	}
	#  doc-scope -- area that the document covers (usually geographic region)
	foreach my $docscope ($docdata->getdocscopeList) {
		print "    Document scope is ".$docscope->getscope."\n";
	}
	#  series -- Identifies article as part of a series
	foreach my $series ($docdata->getseriesList) {
		print "    Document is part of a series:\n";
		print "      Series name: ".$series->getseriesname."\n";
		print "      Part ".$series->getseriespart." of ".$series->getseriestotalpart."\n";
	}
	#  ed-msg -- non-publishable editorial message about the news item
	foreach my $edmsg ($docdata->getedmsgList) {
		print "    Editor's message: ";
		print "      Type: ".$edmsg->getmsgtype."\n";
		print "      Message: ".$edmsg->getinfo."\n";
	}
	#  du-key -- Dynamic Use key: semi-unique ID generated by provider, attached to a story for all
	#            instances. Presumably used to update a story over time.
	foreach my $dukey ($docdata->getdukeyList) {
		print "    Dynamic Use (du) key: ";
		print "      Key = ".$dukey->getkey."\n";
		print "      Generation = ".$dukey->getgeneration."\n";
		print "      Part = ".$dukey->getpart."\n";
		print "      Version = ".$dukey->getversion."\n";
	}
	#  doc-copyright -- Copyright info: "should be consistent with information in the copyrite tag"
	foreach my $doccopyright ($docdata->getdoccopyrightList) {
		print "    Document copyright info: ";
		print "      Holder = ".$doccopyright->getholder."\n";
		print "      Year = ".$doccopyright->getyear."\n";
	}
	#  doc-rights -- Rights holder info:
	#                "should be consistent with information in the series of rights tags"
	foreach my $docrights ($docdata->getdocrightsList) {
		print "    Document rights holder info: ";
		print "      Agent = ".$docrights->getagent."\n";
		print "      Code-source = ".$docrights->getcodesource."\n";
		print "      enddate = ".$docrights->getenddate."\n";
		print "      geography = ".$docrights->getgeography."\n";
		print "      limitations = ".$docrights->getlimitations."\n";
		print "      location-code = ".$docrights->getlocationcode."\n"; # "from standard list"
		print "      owner = ".$docrights->getowner."\n";
		print "      startdate = ".$docrights->getstartdate."\n";
		print "      type = ".$docrights->gettype."\n";
	}
	#  key-list -- List of keywords
	foreach my $keylist ($docdata->getkeylistList) {
		print "    Keyword list:\n";
		foreach my $keyword ($keylist->getkeywordList) {
			print "      Keyword = ".$keyword->getkey."\n";
		}
	}
	#  identified-content -- Content identifiers for this document
	foreach my $contentid ($docdata->getidentifiedcontentList) {
		print "    Content identifiers:\n";
		foreach my $person ($contentid->getpersonList) {
			&parsePerson($person);
		}
		foreach my $org ($contentid->getorgList) {
			&parseOrg($org);
		}
		foreach my $location ($contentid->getlocationList) {
			&parseLocation($location);

		}
	}
}

# the difference between <head> (above) and <body.head> (this stuff) is that the <body.head>
# metadata is intended to be seen by the reader in some form.
sub parseBodyHead {
	my ($bodyhead) = @_;
	print "body head:\n";
	# parse Hedline [sic]
	my $hedline = $bodyhead->gethedline;
	if ($hedline) { 
		print "  Headline:\n";
		&parseEnrichedText($hedline->gethl1);
		foreach my $hl2 ($hedline->gethl2List) {
			print "    subheadline:\n";
			&parseEnrichedText($hl2);
		}
	}
	# parse advisory notes ("potentially publishable")
	print "  Notes:\n";
	foreach my $note ($bodyhead->getnoteList) {
		print "    type: ".$note->gettype."\n"; # defaulut "std" (standard)
		print "    class: ".$note->getnoteclass."\n"; # no default
		# the content of this is actually body.content, so could be anything...
		# as with hl1 & 2, we ignore any markup for now.
		print "    content:".$note->getAllText."\n"; # the whole content
	}
	# parse rights holder information
	print "  Rights:\n";
	my $rights = $bodyhead->getrights;
	if ($rights) {
		print "    rights: ".$rights->getText."\n"; # has PCDATA for display to the reader I guess
		print "      rights owner: ".$rights->getrightsowner->getText."\n";
		print "      rights owner contact: ".$rights->getrightsowner->getcontact."\n";
		print "      rights startdate: ".$rights->getrightsstartdate->getText."\n";
		print "      rights startdate normalised: ".$rights->getrightsstartdate->getnorm."\n";
		print "      rights enddate: ".$rights->getrightsenddate->getText."\n";
		print "      rights enddate normalised: ".$rights->getrightsenddate->getnorm."\n";
		print "      rights agent: ".$rights->getrightsagent->getText."\n";
		print "      rights agent contact: ".$rights->getrightsagent->getcontact."\n";
		print "      rights geography: ".$rights->getrightsgeography->getText."\n";
		print "      rights geography code: ".$rights->getrightsgeography->getlocationcode."\n";
		print "      rights geography code source: ".$rights->getrightsgeography->getcodesource."\n";
		# no controlled vocabulary for this, a bit silly methinks...
		print "      rights type: ".$rights->getrightstype->getText."\n";
		# no controlled vocabulary for this, a bit silly methinks...
		print "      rights limitations: ".$rights->getrightslimitations->getText."\n";
	}
	# parse byline/s
	print "  Byline:\n";
	foreach my $byline ($bodyhead->getbylineList) {
		if ($byline) {
			print "    full byline: ".$byline->getText."\n";
			foreach my $person ($byline->getpersonList) {
				&parsePerson($person);
			}
			foreach my $byttl ($byline->getbyttlList) {
				print "      byline title: ".$byttl->getText."\n";
				foreach my $org ($byttl->getorgList) {
					&parseOrg($org);
				}
			}
			foreach my $location ($byline->getlocationList) {
				&parseLocation($location);
			}
			foreach my $virtloc ($byline->getvirtlocList) {
				print "      virtual location: ".$virtloc->getvalue."\n";
				print "        virtual location data source: ".$virtloc->getidsrc."\n";
				foreach my $altcode ($virtloc->getaltcodeList) {
					print "        (alternate = ".$altcode->getvalue.", from ".$altcode->idsrc.")\n";
				}
			}
		}
	}
	# parse distributor
	my $distributor = $bodyhead->getdistributor;
	if ($distributor) {
		print "    distributor: ".$distributor->getAllText("strip")."\n";
		foreach my $org ($distributor->getorgList) {
			&parseOrg($org);
		}
	}
	# parse dateline
	foreach my $dateline ($bodyhead->getdatelineList) {
		print "    dateline: ".$dateline->getAllText("strip")."\n";
		foreach my $location ($dateline->getlocationList) {
			&parseLocation($location);
		}
		foreach my $storydate ($dateline->getstorydateList) {
			print "      story.date: ".$storydate->getAllText("strip")."\n";
			print "        story.date (norm): ".$storydate->getnorm."\n";
		}
	}
	# parse abstract
	my $abstract = $bodyhead->getabstract;
	if ($abstract) {
		print "    abstract: ".$abstract->getAllText("strip")."\n";
		# has lots of child elements, can't be bothered doing them all right now...
	}

	# parse series
	my $series = $bodyhead->getseries;
	if ($series) {
		print "    series info:\n";
		print "      series name: ".$series->getseriesname."\n";
		print "      series part ".$series->getseriespart." of ".$series->getseriestotalpart."\n";
	}
}

sub parseBodyContent {
	my ($bodycontent) = @_;
	print "body content:\n";
	# print $bodycontent->getXML;
	foreach my $childnode ($bodycontent->getChildrenList) {
		if ($childnode->getTagName eq "nitf-table") {
			# do stuff for tables
			print "  table: number of columns: ".$childnode->getColumnCount."\n";
			print "  table: number of rows: ".$childnode->getRowCount."\n";
		} elsif ($childnode->getTagName eq "media") {
			# do stuff for media
			print "  media:\n";
			print "    media type: ".$childnode->getmediatype."\n";
		} else {
			print "  node: ".$childnode->getTagName.", content: ".$childnode->getAllText."\n";
		}
	}
}

sub parseBodyEnd {
	my ($bodyend) = @_;
	print "body content:\n";
	# parse optional tagline
	my $tagline = $bodyend->gettagline;
	if ($tagline) {
		print "  tagline: ";
		&parseEnrichedText($tagline);
	}
	# parse optional bibliography
	my $bibliography = $bodyend->getbibliography;
	if ($bibliography) {
		# just PCDATA, nothing smart here
		print "  bibliography: ".$bibliography->getText;
	}
}

sub parsePerson {
	my ($person) = @_;
	print "      Person = ".$person->getText."\n";
	foreach my $givenname ($person->getnamegivenList) {
		print "        Given name = ".$givenname->getText."\n";
	}
	foreach my $familyname ($person->getnamefamilyList) {
		print "        Family name = ".$familyname->getText."\n";
	}
	foreach my $function ($person->getfunctionList) {
		print "        Function = ".$function->getvalue."(from ".$function->idsrc.")\n";
		foreach my $altcode ($function->getaltcodeList) {
			print "        (alternate = ".$altcode->getvalue.", from ".$altcode->idsrc.")\n";
		}
	}
}

sub parseLocation {
	my ($location) = @_;
	print "      Location = ".$location->getText."\n";
	print "        location-code = ".$location->getlocationcode."\n";
	print "        class = ".$location->getclass."\n";
	print "        code-source = ".$location->getcodesource."\n";
	print "        style = ".$location->getstyle."\n";
	foreach my $altcode ($location->getaltcodeList) {
		print "        (alternate = ".$altcode->getvalue.", from ".$altcode->idsrc.")\n";
	}
	foreach my $sublocation ($location->getsublocationList) {
		print "      Sublocation = ".$sublocation->getText."\n";
		print "          location-code = ".$sublocation->getlocationcode."\n";
		print "          class = ".$sublocation->getclass."\n";
		print "          code-source = ".$sublocation->getcodesource."\n";
		print "          style = ".$sublocation->getstyle."\n";
		foreach my $altcode ($sublocation->getaltcodeList) {
			print "        (alternate = ".$altcode->getvalue.", from ".$altcode->idsrc.")\n";
		}
	}
	foreach my $city ($location->getcityList) {
		print "      City = ".$city->getText."\n";
		print "          city-code = ".$city->getcitycode."\n";
		print "          class = ".$city->getclass."\n";
		print "          code-source = ".$city->getcodesource."\n";
		print "          style = ".$city->getstyle."\n";
		foreach my $altcode ($city->getaltcodeList) {
			print "        (alternate = ".$altcode->getvalue.", from ".$altcode->idsrc.")\n";
		}
	}
	foreach my $state ($location->getstateList) {
		print "      State = ".$state->getText."\n";
		print "          state-code = ".$state->getstatecode."\n";
		print "          class = ".$state->getclass."\n";
		print "          code-source = ".$state->getcodesource."\n";
		print "          style = ".$state->getstyle."\n";
		foreach my $altcode ($state->getaltcodeList) {
			print "        (alternate = ".$altcode->getvalue.", from ".$altcode->idsrc.")\n";
		}
	}
	foreach my $region ($location->getregionList) {
		print "      Region = ".$region->getText."\n";
		print "          region-code = ".$region->getreginocode."\n";
		print "          class = ".$region->getclass."\n";
		print "          code-source = ".$region->getcodesource."\n";
		print "          style = ".$region->getstyle."\n";
		foreach my $altcode ($region->getaltcodeList) {
			print "        (alternate = ".$altcode->getvalue.", from ".$altcode->idsrc.")\n";
		}
	}
	foreach my $country ($location->getcountryList) {
		print "      country = ".$country->getText."\n";
		print "          iso-cc = ".$country->getisocc."\n";
		print "          class = ".$country->getclass."\n";
		print "          style = ".$country->getstyle."\n";
		foreach my $altcode ($country->getaltcodeList) {
			print "        (alternate = ".$altcode->getvalue.", from ".$altcode->idsrc.")\n";
		}
	}
}

sub parseOrg {
	my ($org) = @_;
	print "      Organisation = ".$org->getText."\n";
	print "        Formally = ".$org->getvalue."(from ".$org->idsrc.")\n";
	foreach my $altcode ($org->getaltcodeList) {
		print "        (alternate = ".$altcode->getvalue.", from ".$altcode->idsrc.")\n";
	}
}

sub parseEnrichedText {
	my ($enrichedtext) = @_;
	print " full enriched text: ".$enrichedtext->getText."\n";
	foreach my $childnode ($enrichedtext->getChildrenList) {
		print "  node: ".$childnode->getTagName.", content: ".$childnode->getAllText."\n";
	}
}
