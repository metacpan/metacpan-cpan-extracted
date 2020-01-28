#!/usr/bin/perl -w
use strict;
use bytes;
use Shout; 


###############################################################################
###	C O N F I G U R A T I O N
###############################################################################
use vars qw{$Debug $Lame};
chomp( $Lame = `which lame` );
my $Bitrate=64;
my $Samplerate = 22050;
### Create a new streaming object
my $streamer = new Shout
	host		=> "localhost",
	port		=> 8000,
	mount		=> "/example2",
	password	=> "hackme",
	format          => SHOUT_FORMAT_MP3,
	protocol        => SHOUT_PROTOCOL_HTTP;

$streamer->set_audio_info(SHOUT_AI_BITRATE => $Bitrate,
  SHOUT_AI_SAMPLERATE => 22050);

###############################################################################
###	M A I N   P R O G R A M
###############################################################################


### Try to connect, aborting on failure
if ( $streamer->open ) {
	printf "Connected to %s port %d...\n", $streamer->host, $streamer->port;
	printf "Will stream to mountpoint '%s'.\n", $streamer->mount;
} else {
	printf "couldn't connect: %s\n", $streamer->get_error;
	exit $streamer->get_errno;
}

### Stream each file specified on the command line
for my $file ( @ARGV ) {

	print STDERR "Can't read '$file': $!" unless -r $file;
	print "Sending $file...\n";

        $streamer->set_metadata(song => "Now Playing: $file");

	### Run lame in downsampling mode on the file we're going to send
	open( LAME, "-|" ) || exec $Lame, qw{--mp3input -b}, $Bitrate, qw{-m j -f -S}, $file, "-";

	my $buff;
	READ: while ((my $len = sysread(LAME, $buff, 4096)) > 0) {
		print STDERR "Read $len bytes...\n" if $Debug;
		$streamer->send( $buff ) && next;

		warn( "send failed: ", $streamer->get_error, "\n" );
		last READ;
	} continue {
		$streamer->sync;
	}

	close LAME;
}

### Disconnect from the server
$streamer->close;

