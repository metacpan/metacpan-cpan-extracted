#!/usr/bin/perl -w
# -*- cperl -*-
# PODNAME: balabolka.pl
# ABSTRACT: script converting textfile named $1
   #                               into file $2
#                          with engine:voice $3
#           using balabolka

use v5.32;
use IO::File;
use IPC::Run;

# Check arguments
die( "Usage: $0 <input_text_file> <output_audio_file> <voice>\n" )
  unless( 3 == @ARGV );

my ( $textfilename, $audiofilename, $voice ) = @ARGV;

# Run balabolka, run!
my $command = [ "balabloka.exe",
		"-mqs",
		$textfilename,
		$audiofilename,
		$voice ];
my $out;
IPC::Run::run( $command, '>', \$out );
exit( $? );
