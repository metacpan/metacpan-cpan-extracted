#!/usr/bin/perl
# This basic example script shows a use for Music::Tag::LyricsFetcher 


use strict;
use Music::Tag;


foreach my $filename (@ARGV) {
	my $info = Music::Tag->new($filename, { quiet => 1 });
	$info->add_plugin("LyricsFetcher");
	$info->get_tag();

	print "Artist:\t", $info->artist, "\n",
		  "Album:\t", $info->album, "\n",
		  "Title:\t", $info->title, "\n",
		  "Lyrics:\t", $info->lyrics;
}

