#!/usr/bin/perl
# This basic example script shows a use for Music::Tag


use strict;
use Music::Tag;

foreach my $filename (@ARGV) {
	my $info = Music::Tag->new($filename, { quiet => 1 });
	$info->add_plugin("MusicBrainz");
	$info->get_tag();
	foreach my $m (sort @{$info->used_datamethods}) {
		if ($m eq "picture") {
			printf "%20s: %s\n", "\u${m}", "Exists"; 
		}
		else {
			printf "%20s: %s\n", "\u${m}", $info->$m; 
		}
	}
}
