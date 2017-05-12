#!/usr/bin/perl

package NewsMLParser;

# displays contents of a NewsML document in somewhat human-readable form.
# to be used as the basis for your own, more useful parsers.

use strict;
use NewsML;

MAIN:
{
	my $filename = $ARGV[0] || die "Usage: $0 <filename to parse>\n";
	my $newsml = new Syndication::NewsML($filename);
	my $env = $newsml->getNewsEnvelope;

	print "Identification info:\n";
	print " Date and time is ".$env->getDateAndTime->getText."\n";
	print " Priority is ".$env->getPriority->getFormalName."\n" if $env->getPriority;
	if ($env->getNewsServiceCount > 0) {
		print " News service: ";
		my $i = 0;
		foreach my $newsservice ($env->getNewsServiceList) {
			print ", " if $i++;
			print $newsservice->getFormalName;
		}
		print "\n";
	}

	print " News item count is ".$newsml->getNewsItemCount."\n";

	my $itemtype;
	my $count = 1;
	foreach my $item ($newsml->getNewsItemList) {
		# get type
		$itemtype = $item->getType;
		print "** News Item ".$count." (".$itemtype.")\n";

		# get identification
		print "Identification info:\n";
		my $identifier = $item->getIdentification->getNewsIdentifier;
		print " Provider id: ".$identifier->getProviderId->getText."\n";
		print " Date id: ".$identifier->getDateId->getText."\n";
		print " Revision id: ".$identifier->getRevisionId->getText
			. " (update = ". $identifier->getRevisionId->getUpdate
			. ", Previous Revision = ".$identifier->getRevisionId->getPreviousRevision.")"
			. "\n";
		print " Public identifier: ".$identifier->getPublicIdentifier->getText."\n";
		my $namelabel = $item->getIdentification->getNameLabel;
		print " Name Label: ".$namelabel->getText."\n" if $namelabel;

		# get management info
		print "Management info:\n";
		my $management = $item->getNewsManagement;
		print " NewsItemType: ".$management->getNewsItemType->getFormalName."\n";
		print " First created: ".$management->getFirstCreated->getText."\n";
		my $tstamp = $management->getFirstCreated->getDatePerl;
		print " First created (Perl): ".$tstamp."\n";
		my ($ss, $mi, $hh, $dd, $mm, $yy) = gmtime($tstamp);
		print " which translates in UTC to ".sprintf("%4d/%02d/%02d %02d:%02d:%02d",1900+$yy,$mm+1,$dd,$hh,$mi,$ss)."\n";
		($ss, $mi, $hh, $dd, $mm, $yy) = localtime($tstamp);
		print " which translates in local timezone to ".sprintf("%4d/%02d/%02d %02d:%02d:%02d",1900+$yy,$mm+1,$dd,$hh,$mi,$ss)."\n";

		print " This revision created: ".$management->getThisRevisionCreated->getText."\n";
		print " Status: ".$management->getStatus->getFormalName."\n";
		# should deal with types of status (embargoed etc)
		print " Urgency: ".$management->getUrgency->getFormalName."\n" if $management->getUrgency;

		if ($itemtype eq "NewsComponent") {
			my $comp = $item->getNewsComponent;

			# parse a news component (the most common type of NewsItem)
			&parseNewsComponent($comp, 0);
		} elsif ($itemtype eq "Update") {
			my $update = $item->getUpdate;
			print "got update\n";
			print " ...\n";
		} elsif ($itemtype eq "TopicSet") {
			my $topicset = $item->getTopicSet;
			print "got topicset\n";
			print " ...\n";
		} else {
			print "no NewsComponent, Update or TopicSet -- strange, but legal\n";
		}
	}
}

# parse a news component (the most common type of NewsItem)
sub parseNewsComponent {
	my ($newscomp, $indent) = @_;
	print " " x $indent . "News Component:\n";
	print " " x $indent . " Role: ".$newscomp->getRole->getFormalName."\n" if $newscomp->getRole;
	my $equiv = $newscomp->getEquivalentsList;
	print " " x $indent . " Equivalents list: ".$equiv;
	if ($equiv eq "yes") {
		if ($newscomp->getBasisForChoiceCount > 0) {
			print " (basis for choice: ";
			my $i = 0;
			foreach my $basis ($newscomp->getBasisForChoiceList) {
				print ", " if $i++;
				print $basis->getText;
				print " (rank=".$basis->getRank.")" if $basis->getRank;
			}
			print ")";
		}
	}
	print "\n";
	if (my $adminmeta = $newscomp->getAdministrativeMetadata) {
		print " " x $indent . " Administrative Metadata:\n";
		if ($adminmeta->getProvider) {
			print " " x $indent . "  Provider: ";
			&parseParties($adminmeta->getProvider->getPartyList);
			print "\n";
		}
		if ($adminmeta->getCreator) {
			print " " x $indent . "  Creator: ";
			&parseParties($adminmeta->getCreator->getPartyList);
			print "\n";
		}
		if ($adminmeta->getSourceCount > 0) {
			foreach my $source ($adminmeta->getSourceList) {
				print " " x $indent . "  Source: ";
				&parseParties($source->getPartyList);
				print "\n";
			}
		}
		if ($adminmeta->getContributorCount > 0) {
			foreach my $contributor ($adminmeta->getContributorList) {
				print " " x $indent . "  Contributor: ";
				&parseParties($contributor->getPartyList);
				print "\n";
			}
		}
	}
	if (my $descmeta = $newscomp->getDescriptiveMetadata) {
		print " " x $indent . " Descriptive Metadata:\n";
		if ($descmeta->getLanguageCount > 0) {
			print " " x $indent . "  Language: ";
			my $i = 0;
			foreach my $language ($descmeta->getLanguageList) {
				print ", " if $i++;
				print $language->getFormalName;
			}
			print "\n";
		}
		if ($descmeta->getSubjectCodeCount > 0) {
			print " " x $indent . "  SubjectCode: ";
			foreach my $subjectcode ($descmeta->getSubjectCodeList) {
				if ($subjectcode->getSubjectCount > 0) {
					print " " x $indent . "  Subject: ";
					my $i = 0;
					foreach my $subject ($subjectcode->getSubjectList) {
						print ", " if $i++;
						print $subject->getFormalName;
					}
				}
			}
			print "\n";
		}
		if ($descmeta->getPropertyCount > 0) {
			print " " x $indent . "  Properties: ";
			&parseProperties($indent, $descmeta->getPropertyList);
			print ")\n";
		}
	}
	if (my $rightsmeta = $newscomp->getRightsMetadata) {
		print " " x $indent . " Rights Metadata:\n";
		if ($rightsmeta->getCopyrightCount > 0) {
			# copyright holder and copyright date are both required:
			# use the helper routines in the NewsComponent class
			print " " x $indent . "  Copyright holder: ".$newscomp->getCopyrightHolder."\n";
			print " " x $indent . "  Copyright date: ".$newscomp->getCopyrightDate."\n";
		}
	}
	# arbitrary metadata
	if ($newscomp->getMetadataCount > 0) {
		print " " x $indent . " Other Metadata:\n";
		foreach my $meta ($newscomp->getMetadataList) {
			print " " x $indent . "  Metadata: ".$meta->getMetadataType->getFormalName."\n";
			if ($meta->getPropertyCount > 0) {
				print " " x $indent . "   Properties: ";
				&parseProperties($indent, $meta->getPropertyList);
				print "\n";
			}
		}
	}
	# look for child news components
	my $childnewscomps = $newscomp->getNewsComponentList;
	foreach my $childnewscomp (@$childnewscomps) {
		&parseNewsComponent($childnewscomp, $indent + 2);
	}
	# look for child content items
	my $childcontentitems = $newscomp->getContentItemList;
	foreach my $childcontentitem (@$childcontentitems) {
		&parseContentItem($childcontentitem, $indent + 2);
	}
}

# parse a news component (the most common type of NewsItem)
sub parseContentItem {
	my ($contentitem, $indent) = @_;
	print " " x $indent . "Content Item:\n";
	print " " x $indent . " Href: ".$contentitem->getHref."\n" if $contentitem->getHref;
	print " " x $indent . " Media Type: ".$contentitem->getMediaType->getFormalName."\n" if $contentitem->getMediaType;
	print " " x $indent . " Mime Type: ".$contentitem->getMimeType->getFormalName."\n" if $contentitem->getMimeType;
	print " " x $indent . " Format: ".$contentitem->getFormat->getFormalName."\n" if $contentitem->getFormat;
	print " " x $indent . " Notation: ".$contentitem->getNotation->getFormalName."\n" if $contentitem->getNotation;
	if (my $characteristics = $contentitem->getCharacteristics) {
		print " " x $indent . " Characteristics:\n";
		print " " x $indent . "  SizeInBytes: ".$characteristics->getSizeInBytes->getText."\n" if $characteristics->getSizeInBytes;
		if ($characteristics->getPropertyCount > 0) {
			print " " x $indent . "  Properties: ";
			&parseProperties($indent, $characteristics->getPropertyList);
			print "\n";
		}
	}
}

sub parseProperties {
	my ($indent, @properties) = @_;
	my $i = 0;
	foreach my $property (@properties) {
		print ", " if $i++;
		print $property->getFormalName." = ".$property->getValue;
		if ($property->getPropertyCount > 0) {
			print "[ ";
			&parseProperties($indent+2, $property->getPropertyList);
			print " ]";
		}
	}
}

# print party FormalNames on one line separated by commas
sub parseParties {
	my (@parties) = @_;
	my $i = 0;
	foreach my $party (@parties) {
		print ", " if $i++;
		print $party->getFormalName;
	}
}
