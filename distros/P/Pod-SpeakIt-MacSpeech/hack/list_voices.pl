#!/usr/bin/perl
use strict;
use warnings;

use Mac::Files;
use Mac::Speech;

my $voice_dir = FindFolder(kOnSystemDisk, kVoicesFolderType);

print "Voice directory is $voice_dir\n";

opendir my( $dh ), $voice_dir;
my @voice_files = grep /\w/, readdir $dh;

printf "There are %d count voices\n", CountVoices() + 1;
print "@voice_files\n";

foreach my $voice ( keys %Mac::Speech::Voice )
	{
	print "\tvoice is $voice\n";
	
	my $desc    = GetVoiceDescription($voice);	
	my $channel = NewSpeechChannel($voice);

	foreach my $key ( qw(name gender age) )
		{
		print "\t$key => ", $desc->$key(), "\n";
		}
	}

