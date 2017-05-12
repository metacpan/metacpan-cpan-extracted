#!/usr/bin/perl
use strict;
use warnings;

use Mac::Files;
use Mac::Speech;

my %Genders = ( 0 => 'Neutral', 1 => 'Male', 2 => 'Female' );

my $voice_dir = FindFolder(kOnSystemDisk, kVoicesFolderType);

print "Voice directory is $voice_dir\n";

if( $ARGV[0] )
	{
	local $| = 1;
	
	my $voice   = $Mac::Speech::Voice{ $ARGV[0] };
	die "Don't know about the voice [$voice]\n" unless $voice;
	
	my $channel = NewSpeechChannel($voice);

	my $base_rate  = GetSpeechRate( $channel );
	my $base_pitch = GetSpeechPitch( $channel );
	
	foreach my $rate ( 7 .. 13 )
		{
		$rate /= 10;
		
		SetSpeechRate( $channel, $rate * $base_rate );
		
		print "Rate [$rate] =>  ";
		foreach my $pitch ( 7 .. 13 )
			{
			$pitch /= 10;
			
			print "$pitch  ";
			
			SetSpeechPitch( $channel, $pitch * $base_pitch );

			SpeakText( $channel, "Buster Bean, come here, I need you!" );
			sleep 1 while SpeechBusy();			
			}
			
		print "\n";
		}
		
	}
else
	{
	opendir my( $dh ), $voice_dir;
	my @voice_files = grep /\w/, readdir $dh;
	my @voices = map { /(.*?)\.SpeechVoice/ } @voice_files;
	
	printf "There are %d count voices\n", CountVoices() + 1;
	print "@voice_files\n";
	
	printf "%-20s %-10s %s\n", qw(Name Gender Age);
	print "-" x 45, "\n";
	
	foreach my $voice_name ( @voices )
		{
		my $voice   = $Mac::Speech::Voice{$voice_name};
		my $desc    = eval { GetVoiceDescription($voice) };
		next if $@;
		my $channel = NewSpeechChannel($voice);
	
		printf "%-20s %-10s %3d\n", 
			$desc->name, $Genders{ $desc->gender }, $desc->age;
				
		SpeakText( $channel, "Buster Bean, come here, I need you!" );
		sleep 1 while SpeechBusy();
		
		DisposeSpeechChannel( $channel )
		}
	}