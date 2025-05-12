#!/usr/bin/perl -w
# -*- cperl -*-
# PODNAME: festival.pl
# ABSTRACT: script converting textfile named $1
   #                               into file $2
#                          with engine:voice $3
#           using festival

use v5.32;
use IO::File;
use IPC::Run;

# Check arguments
die( "Usage: $0 <input_text_file> <output_audio_file> <voice>\n" )
  unless( 3 == @ARGV );

my ( $textfilename, $audiofilename, $voice ) = @ARGV;

# determine format from audiofilename
my $format = $audiofilename;
$format =~ s/.+\.([^\.]+)/$1/;

# Run festival, run!
my $command = [
	       "text2wave",
	       "-eval",
	       "(voice_$voice)",
	       "-o",
	       "$audiofilename.wav",
	       "$textfilename"
	      ];
my $out;
IPC::Run::run( $command,
	       '>',  \$out );
die( "Error: could not start festival's 'text2wave'\n" ) if ( $? );

foreach ( $format ) {
  'mp3' and do {
    $command = [ "lame",
		 "$audiofilename.wav",
		 "$audiofilename" ];
    last;
  };
  'ogg' and do {
    $command = [ "oggenc",
		 "-o",
		 "$audiofilename",
		 "$audiofilename.wav" ];
    last;
  };
  die( "Error: could not guess audio format based on output audiofilename\n" );
}
IPC::Run::run( $command,
	       '>',  \$out );
exit($?) if ($?);
unlink "$audiofilename.wav";
exit(0);

__END__

=pod

=encoding UTF-8

=head1 NAME

festival.pl - script converting textfile named $1

=head1 VERSION

version 20250511.1428

=head1 AUTHOR

Walter Daems <wdaems@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Walter Daems.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=head1 CONTRIBUTOR

=for stopwords Paul Levrie

Paul Levrie

=cut
