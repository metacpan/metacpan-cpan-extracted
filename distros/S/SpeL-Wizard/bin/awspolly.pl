#!/usr/bin/perl -w
# -*- cperl -*-
# PODNAME: awspollymp3.pl
# ABSTRACT: script converting textfile named $1
   #                               into file $2
#                          with engine:voice $3
#           using AWS Polly

use v5.32;
use IO::File;
use IPC::Run;

# Check arguments
die( "Usage: $0 <input_text_file> <output_audio_file> <engine:voice>\n" )
  unless( 3 == @ARGV );

my ( $textfilename, $audiofilename, $engvoice ) = @ARGV;

# determine format from audiofilename
my $format = $audiofilename;
$format =~ s/.+\.([^\.]+)/$1/;
foreach ( $format ) {
  'mp3' and do {
    $format = 'mp3';
    last;
  };
  'ogg' and do {
    $format = 'ogg_vorbis';
    last;
  };
  die( "Error: could not guess audio format based on output audiofilename\n" );
}

# determine engine and voice
my ( $engine, $voice ) = split( /:/, $engvoice );
    die( "Invalid engine or voice format. Use <engine:voice>.\n" )
      
  unless( defined $engine and defined $voice );

# read text file
my $textfile = IO::File->new();
$textfile->open( "<$textfilename" )
  or die( "Error: cannot open '$textfilename'\n" );
my $text = do { local $/; <$textfile> };

# Run polly, run!
my $command = [
	       "aws",
	       "polly",
	       "synthesize-speech",
	       "--output-format",
	       $format,
	       "--engine",
	       $engine,
	       "--voice-id",
	       $voice,
	       "--text",
	       "$text",
	       $audiofilename
	      ];
my $out;
IPC::Run::run( $command,
	       '>',  \$out );
exit($?);
