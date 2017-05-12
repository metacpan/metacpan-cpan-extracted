package Ogg::Vorbis::LibVorbis;

use 5.008000;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# This allows declaration	use Ogg::Vorbis::LibVorbis ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	INITSET
	NOTOPEN
	OPENED
	OV_EBADHEADER
	OV_EBADLINK
	OV_EBADPACKET
	OV_ECTL_IBLOCK_GET
	OV_ECTL_IBLOCK_SET
	OV_ECTL_LOWPASS_GET
	OV_ECTL_LOWPASS_SET
	OV_ECTL_RATEMANAGE2_GET
	OV_ECTL_RATEMANAGE2_SET
	OV_ECTL_RATEMANAGE_AVG
	OV_ECTL_RATEMANAGE_GET
	OV_ECTL_RATEMANAGE_HARD
	OV_ECTL_RATEMANAGE_SET
	OV_EFAULT
	OV_EIMPL
	OV_EINVAL
	OV_ENOSEEK
	OV_ENOTAUDIO
	OV_ENOTVORBIS
	OV_EOF
	OV_EREAD
	OV_EVERSION
	OV_FALSE
	OV_HOLE
	PARTOPEN
	STREAMSET
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	INITSET
	NOTOPEN
	OPENED
	OV_EBADHEADER
	OV_EBADLINK
	OV_EBADPACKET
	OV_ECTL_IBLOCK_GET
	OV_ECTL_IBLOCK_SET
	OV_ECTL_LOWPASS_GET
	OV_ECTL_LOWPASS_SET
	OV_ECTL_RATEMANAGE2_GET
	OV_ECTL_RATEMANAGE2_SET
	OV_ECTL_RATEMANAGE_AVG
	OV_ECTL_RATEMANAGE_GET
	OV_ECTL_RATEMANAGE_HARD
	OV_ECTL_RATEMANAGE_SET
	OV_EFAULT
	OV_EIMPL
	OV_EINVAL
	OV_ENOSEEK
	OV_ENOTAUDIO
	OV_ENOTVORBIS
	OV_EOF
	OV_EREAD
	OV_EVERSION
	OV_FALSE
	OV_HOLE
	PARTOPEN
	STREAMSET
);

our $VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Ogg::Vorbis::LibVorbis::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	*$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Ogg::Vorbis::LibVorbis', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__


=head1 NAME

Ogg::Vorbis::LibVorbis - XS Interface for calling Vorbis Audio Codec functions in Perl.

=head1 DESCRIPTION

Ogg::Theora::LibVorbis is a glue between vorbis/codec.h, vorbis/vorbisenc.h and vorbis/vorbisfile.h
Please read the XS code to understand how the gluing happens.

=head1 SYNOPSIS ENCODE

Encoding .wav format to Vorbis Audio format L<http://svn.xiph.org/trunk/vorbis/examples/encoder_example.c>

  ##############################################################################################################################################################
  # (1) Initialize a vorbis_info structure by calling vorbis_info_init and then functions from libvorbisenc on it.			   		       #
  # (2) Initialize a vorbis_dsp_state for encoding based on the parameters in the vorbis_info by using vorbis_analysis_init.				       #
  # (3) Initialize a vorbis_comment structure using vorbis_comment_init, populate it with any comments you wish to store 				       #
  #     in the stream, and call vorbis_analysis_headerout to get the three Vorbis stream header packets. Output the packets.				       #
  # (4) Initialize a vorbis_block structure using vorbis_block_init.											       #
  # (5) While there is more audio to encode:														       #
  #       (5.a) Submit a chunk of audio data using vorbis_analysis_buffer and vorbis_analysis_wrote.							       #
  #       (5.b) Obtain all available blocks using vorbis_analysis_blockout in a loop. For each block obtained:						       #
  #           (5.b.1) Encode the block into a packet (or prepare it for bitrate management) using vorbis_analysis.					       #
  #           (5.b.2) If you are using bitrate management, submit the block using vorbis_bitrate_addblock and obtain packets using vorbis_bitrate_flushpacket. #
  #           (5.b.3) Output any obtained packets.													       #
  # (6) Submit an empty buffer to indicate the end of input; this will result in an end-of-stream packet after all encoding steps are done to it.	       #
  # (7) Destroy the structures using the appropriate vorbis_*_clear routines.										       #
  ##############################################################################################################################################################


  use Ogg::LibOgg ':all';
  use Ogg::Vorbis::LibVorbis;
  use Audio::Wav;

  ## Wav Audio File Info
  my $wav = new Audio::Wav; 
  my $read = $wav->read("t/test.wav"); 
  my $details = $read->details();
  my $channels = $details->{channels}; # 2
  my $rate = $details->{sample_rate};  # 22050
  my $length = $read->length_samples(); # 48066

  ## Ogg Pages
  my $op_h      = make_ogg_packet();
  my $op_hcomm = make_ogg_packet();
  my $op_hcode = make_ogg_packet();
  my $op_audio   = make_ogg_packet();
  my $os   = make_ogg_stream_state();
  my $og = make_ogg_page();

  my $vi = Ogg::Vorbis::LibVorbis::make_vorbis_info(); # vorbis_info
  my $vc = Ogg::Vorbis::LibVorbis::make_vorbis_comment(); # vorbis_comment
  my $vb = Ogg::Vorbis::LibVorbis::make_vorbis_block(); # vorbis_block
  Ogg::Vorbis::LibVorbis::vorbis_info_init($vi);
  my $v = Ogg::Vorbis::LibVorbis::make_vorbis_dsp_state(); # vorbis_dsp_state
  my $ret = Ogg::Vorbis::LibVorbis::vorbis_encode_init_vbr($vi, $channels, $rate, 1.0);
  $ret = Ogg::Vorbis::LibVorbis::vorbis_analysis_init($v, $vi);
  $ret = Ogg::Vorbis::LibVorbis::vorbis_encode_setup_init($vi);
  Ogg::Vorbis::LibVorbis::vorbis_comment_init($vc);
  $ret = Ogg::Vorbis::LibVorbis::vorbis_block_init($v, $vb);
  $ret = Ogg::Vorbis::LibVorbis::vorbis_analysis_headerout($v, $vc, $op_h, $op_hcomm, $op_hcode);

  $ret = ogg_stream_init($os, int(rand(1000)));
  $ret = ogg_stream_packetin($os, $op_h);
  $ret = ogg_stream_packetin($os, $op_hcomm);
  $ret = ogg_stream_packetin($os, $op_hcode);

  my $filename = "t/vorbis_encode.ogg";
  open OUT, ">", "$filename" or die "can't open $filename for writing [$!]";
  binmode OUT;

  save_page();
  1 while (add_frames());

  close OUT;

  sub save_page {
    ## forms packets to pages 
    if (ogg_stream_pageout($os, $og) != 0) {
      my $h_page = get_ogg_page($og);
      ## writes the header and body 
      print OUT $h_page->{header};
      print OUT $h_page->{body};
    } else {
      # pass, we don't have to worry about insufficient data
    }
  }
  
  sub add_frames {
    my $data = $read->read_raw_samples($channels);
    my $no = $read->position_samples();  
  
    # vorbis_encode_wav_frames(v, vals, channels, buffer)
    my $status = Ogg::Vorbis::LibVorbis::vorbis_encode_wav_frames($v, 1024, $channels, $data);
  
    # while (vorbis_analysis_blockout(self.vd, self.vb) == 1)
    # 	vorbis_analysis(self.vb,self.audio_pkt)
    # 	ogg_stream_packetin(self.to,self.audio_pkt)
    while (($status = Ogg::Vorbis::LibVorbis::vorbis_analysis_blockout($v, $vb)) == 1) {
      $status = Ogg::Vorbis::LibVorbis::vorbis_analysis($vb, $op_audio);
      if ($status < 0) {
        diag ("Crap Out, some error [$status]");
        exit -1;
      }
      ogg_stream_packetin($os, $op_audio);
    }
  
    save_page();
  
    return $length == $no ? 0 : 1
  }


=head1 SYNOPSIS DECODE (vorbisfile)

Decoding Vorbis file using vorbisfile L<http://xiph.org/vorbis/doc/vorbisfile/example.html>

  use Ogg::Vorbis::LibVorbis;
  use Ogg::LibOgg ':all';

  my $vf = Ogg::Vorbis::LibVorbis::make_oggvorbis_file();  # OggVorbis_File
  my $vi = Ogg::Vorbis::LibVorbis::make_vorbis_info();     # vorbis_info

  my $filename = "t/test.ogg";
  open IN, $filename or die "can't open [$filename] : $!"; 

  $status = Ogg::Vorbis::LibVorbis::ov_open_callbacks(*IN, $vf, 0, 0);  # $status == 0
  my $pcmout = 0;		# i know setting to -1 is of no use, but to avoid warning (_xs_ says NO_INIT)
  my $bit = 0;
  my $ret = -1;
  open OUT, "> output.pcm" or die "can't open output.pcm\n";
  binmode OUT;
  my $total = 0;
  while ($ret != 0) {
    $ret = Ogg::Vorbis::LibVorbis::ov_read($vf, $pcmout, 4096, 0, 2, 1, $bit);
    print OUT $pcmout;
  }
  close OUT;

  Ogg::Vorbis::LibVorbis::ov_clear($vf);


=head2 EXPORT

Only constants are exported by DEFAULT

  use Ogg::Theora::LibVorbis ':all'; # to export everything to current namespace

=head2 Exportable constants

  INITSET
  NOTOPEN
  OPENED
  OV_EBADHEADER
  OV_EBADLINK
  OV_EBADPACKET
  OV_ECTL_IBLOCK_GET
  OV_ECTL_IBLOCK_SET
  OV_ECTL_LOWPASS_GET
  OV_ECTL_LOWPASS_SET
  OV_ECTL_RATEMANAGE2_GET
  OV_ECTL_RATEMANAGE2_SET
  OV_ECTL_RATEMANAGE_AVG
  OV_ECTL_RATEMANAGE_GET
  OV_ECTL_RATEMANAGE_HARD
  OV_ECTL_RATEMANAGE_SET
  OV_EFAULT
  OV_EIMPL
  OV_EINVAL
  OV_ENOSEEK
  OV_ENOTAUDIO
  OV_ENOTVORBIS
  OV_EOF
  OV_EREAD
  OV_EVERSION
  OV_FALSE
  OV_HOLE
  PARTOPEN
  STREAMSET

=head1 Functions (malloc)

L<http://www.xiph.org/vorbis/doc/vorbisfile/datastructures.html>


=head2 make_oggvorbis_file

Creates a memory allocation for OggVorbis_File datastructure

-Input:
  Void

-Output:
  Memory Pointer


=head1 make_vorbis_info

Creates a memory allocation for vorbis_info

-Input:
  void

-Output:
  Memory Pointer to vorbis_info


=head1 make_vorbis_comment

Creates a memory allocation for vorbis_comment

-Input:
  void

-Output:
  Memory Pointer to vorbis_comment


=head1 make_vorbis_block

Creates a memory allocation for vorbis_block

-Input:
  void

-Output:
  Memory Pointer to vorbis_block


=head1 make_vorbis_dsp_state

Creates a memory allocation for vorbis_dsp_state

-Input:
  void

-Output:
  Memory Pointer to vorbis_dsp_state


=head1 Functions (vorbisfile)

L<http://www.xiph.org/vorbis/doc/vorbisfile/reference.html>


=head2 ov_open

ov_open is one of three initialization functions used to initialize an OggVorbis_File 
structure and prepare a bitstream for playback. 
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_open.html>

-Input:
  FILE *, File pointer to an already opened file or pipe,
  OggVorbis_File, A pointer to the OggVorbis_File structure,
  char *, Typically set to NULL,
  int, Typically set to 0.

-Output:
  0 indicates succes,
  less than zero for failure:

    OV_EREAD - A read from media returned an error.
    OV_ENOTVORBIS - Bitstream is not Vorbis data.
    OV_EVERSION - Vorbis version mismatch.
    OV_EBADHEADER - Invalid Vorbis bitstream header.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.


=head2 ov_fopen

This is the simplest function used to open and initialize an OggVorbis_File structure.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_fopen.html>

-Input:
  char *, (null terminated string containing a file path suitable for passing to fopen())
  OggVorbis_File

-Output:
  0 indicates success
  less than zero for failure:

    OV_EREAD - A read from media returned an error.
    OV_ENOTVORBIS - Bitstream does not contain any Vorbis data.
    OV_EVERSION - Vorbis version mismatch.
    OV_EBADHEADER - Invalid Vorbis bitstream header.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.


=head2 ov_open_callbacks

an alternative function used to open and initialize an OggVorbis_File structure when using a data source 
other than a file, when its necessary to modify default file access behavior.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_open.html>

B<Please read the official ov_open_callbacks doc before you use this.> The perl version uses
a different approach and uses vorbis_callbacks with custom functions to read, seek tell and close.

B<this module can accept file name, network socket or a file pointer.>

-Input:
  void *, (data source)
  OggVorbis_File, A pointer to the OggVorbis_File structure,
  char *, Typically set to NULL,
  int, Typically set to 0.

-Output:
  0 indicates succes,
  less than zero for failure:

    OV_EREAD - A read from media returned an error.
    OV_ENOTVORBIS - Bitstream is not Vorbis data.
    OV_EVERSION - Vorbis version mismatch.
    OV_EBADHEADER - Invalid Vorbis bitstream header.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.


=head2 ov_test

This partially opens a vorbis file to test for Vorbis-ness.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_test.html>

-Input:
  FILE *, File pointer to an already opened file or pipe,
  OggVorbis_File, A pointer to the OggVorbis_File structure,
  char *, Typically set to NULL,
  int, Typically set to 0.

-Output:
  0 indicates succes,
  less than zero for failure:

    OV_EREAD - A read from media returned an error.
    OV_ENOTVORBIS - Bitstream is not Vorbis data.
    OV_EVERSION - Vorbis version mismatch.
    OV_EBADHEADER - Invalid Vorbis bitstream header.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.


=head2 ov_test_open

Finish opening a file partially opened with ov_test() or ov_test_callbacks(). 
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_test_open.html>

-Input:
  OggVorbis_File

-Output:
  0 indicates succes,
  less than zero for failure:

    OV_EREAD - A read from media returned an error.
    OV_ENOTVORBIS - Bitstream is not Vorbis data.
    OV_EVERSION - Vorbis version mismatch.
    OV_EBADHEADER - Invalid Vorbis bitstream header.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.


=head2 ov_test_callbacks

an alternative function used to open and test an OggVorbis_File structure when using a data source
other than a file, when its necessary to modify default file access behavior.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_test_callbacks.html>

B<Please read the official ov_test_callbacks doc before you use this.> The perl version uses
a different approach and uses vorbis_callbacks with custom functions to read, seek tell and close.

B<this module can accept file name, network socket or a file pointer.>

-Input:
  void *, (data source)
  OggVorbis_File, A pointer to the OggVorbis_File structure,
  char *, Typically set to NULL,
  int, Typically set to 0.

-Output:
  0 indicates succes,
  less than zero for failure:

    OV_EREAD - A read from media returned an error.
    OV_ENOTVORBIS - Bitstream is not Vorbis data.
    OV_EVERSION - Vorbis version mismatch.
    OV_EBADHEADER - Invalid Vorbis bitstream header.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.


=head2 ov_clear

ov_clear() to clear the decoder's buffers and close the file
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_clear.html>

-Input:
  OggVorbis_File

-Output:
  0 for success


=head2 ov_seekable

This indicates whether or not the bitstream is seekable. 
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_seekable.html>

-Input:
  OggVorbis_File

-Output:
  0 indicates that the file is not seekable.
  nonzero indicates that the file is seekable.


=head2 ov_time_total

Returns the total time in seconds of the physical bitstream or a specified logical bitstream. 
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_time_total.html>

-Input:
  OggVorbis_File,
  int (link to the desired logical bitstream)

-Output:
  OV_EINVAL means that the argument was invalid. In this case, the requested bitstream did not exist or the bitstream is nonseekable.
  n total length in seconds of content if i=-1.
  n length in seconds of logical bitstream if i=0 to n.


=head2 ov_time_seek

For seekable streams, this seeks to the given time.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_time_seek.html>

-Input:
  OggVorbis_File,
  double (location to seek in seconds)

-Output:
  0 for success
  nonzero indicates failure, described by several error codes:

    OV_ENOSEEK - Bitstream is not seekable.
    OV_EINVAL - Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.
    OV_EREAD - A read from media returned an error.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EBADLINK - Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.


=head2 ov_raw_seek

For seekable streams, this seeks to the given offset in compressed raw bytes.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_raw_seek.html>

-Input:
  OggVorbis_File,
  long (location to seek in compressed raw bytes)

-Output:
  0 for success
  nonzero indicates failure, described by several error codes:

    OV_ENOSEEK - Bitstream is not seekable.
    OV_EINVAL - Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.
    OV_EREAD - A read from media returned an error.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EBADLINK - Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.


=head2 ov_pcm_seek

Seeks to the offset specified (in pcm samples) within the physical bitstream.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_pcm_seek.html>

-Input:
  OggVorbis_File,
  ogg_int64_t, (location to seek in pcm samples)

-Output:
  0 for success
  nonzero indicates failure, described by several error codes:

    OV_ENOSEEK - Bitstream is not seekable.
    OV_EINVAL - Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.
    OV_EREAD - A read from media returned an error.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EBADLINK - Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.


=head2 ov_pcm_seek_page

Seeks to the closest page preceding the specified location (in pcm samples).
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_pcm_seek_page.html>

-Input:
  OggVorbis_File,
  ogg_int64_t (position in pcm samples to seek to in the bitstream)

-Output:
  0 for success
  nonzero indicates failure, described by several error codes:

    OV_ENOSEEK - Bitstream is not seekable.
    OV_EINVAL - Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.
    OV_EREAD - A read from media returned an error.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EBADLINK - Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.


=head2 ov_time_seek_page

For seekable streams, this seeks to closest full page preceding the given time.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_time_seek_page.html>

-Input:
  OggVorbis_File,
  double (Location to seek to within the file, specified in seconds)

-Output:
  0 for success
  nonzero indicates failure, described by several error codes:

    OV_ENOSEEK - Bitstream is not seekable.
    OV_EINVAL - Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.
    OV_EREAD - A read from media returned an error.
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EBADLINK - Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.


=head2 ov_raw_seek_lap

Seeks to the offset specified (in compressed raw bytes) within the physical bitstream.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_raw_seek_lap.html>

-Input:
  OggVorbis_File,
  ogg_int64_t (Location to seek to within the file, specified in compressed raw bytes)

-Output:
  0 for success
  nonzero indicates failure, described by several error codes:

    OV_ENOSEEK - Bitstream is not seekable.
    OV_EINVAL - Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.
    OV_EREAD - A read from media returned an error.
    OV_EOF - Indicates stream is at end of file immediately after a seek
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EBADLINK - Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.


=head2 ov_pcm_seek_lap

Seeks to the offset specified (in pcm samples) within the physical bitstream.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_pcm_seek_lap.html>

-Input:
  OggVorbis_File,
  long (Location to seek to within the file, specified in pcm samples)

-Output:
  0 for success
  nonzero indicates failure, described by several error codes:

    OV_ENOSEEK - Bitstream is not seekable.
    OV_EINVAL - Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.
    OV_EREAD - A read from media returned an error.
    OV_EOF - Indicates stream is at end of file immediately after a seek
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EBADLINK - Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.


=head2 ov_time_seek_lap

Seeks to the offset specified (in seconds) within the physical bitstream.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_time_seek_lap.html>

-Input:
  OggVorbis_File,
  double (Location to seek to within the file, specified in seconds)

-Output:
  0 for success
  nonzero indicates failure, described by several error codes:

    OV_ENOSEEK - Bitstream is not seekable.
    OV_EINVAL - Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.
    OV_EREAD - A read from media returned an error.
    OV_EOF - Indicates stream is at end of file immediately after a seek
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EBADLINK - Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.


=head2 ov_time_page_seek_lap

For seekable streams, ov_time_seek_page_lap seeks to the closest full page preceeding the given time.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_time_seek_page_lap.html>

-Input:
  OggVorbis_File,
  double (Location to seek to within the file, specified in seconds)

-Output:
  0 for success
  nonzero indicates failure, described by several error codes:

    OV_ENOSEEK - Bitstream is not seekable.
    OV_EINVAL - Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.
    OV_EREAD - A read from media returned an error.
    OV_EOF - Indicates stream is at end of file immediately after a seek
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EBADLINK - Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.


=head2 ov_pcm_page_seek_lap

Seeks to the closest page preceding the specified location (in pcm samples) within the physical bitstream.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_pcm_seek_page_lap.html>

-Input:
  OggVorbis_File,
  ogg_int64_t (Location to seek to within the file, specified in pcm samples)

-Output:
  0 for success
  nonzero indicates failure, described by several error codes:

    OV_ENOSEEK - Bitstream is not seekable.
    OV_EINVAL - Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.
    OV_EREAD - A read from media returned an error.
    OV_EOF - Indicates stream is at end of file immediately after a seek
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EBADLINK - Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.


=head2 ov_streams

Returns the number of logical bitstreams within our physical bitstream. 
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_streams.html>

-Input:
  OggVorbis_File

-Output:
  1 indicates a single logical bitstream or an unseekable file,
  n indicates the number of logical bitstreams.


=head2 ov_info

Returns the vorbis_info struct for the specified bitstream.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_info.html>

-Input:
  OggVorbis_File,
  int (link to desired logical bitstream)

-Output:
  Returns the vorbis_info struct for the specified bitstream,
  NULL if the specified bitstream does not exist or the file has been initialized improperly.


=head2 ov_bitrate

Function returns the average bitrate for the specified logical bitstream. 
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_bitrate.html>

-Input:
  OggVorbis_File,
  int (desired logical bitstream)

-Output:
    OV_EINVAL indicates that an invalid argument value or that the stream represented by vf is not open,
    OV_FALSE means the call returned a 'false' status, 
    n indicates the bitrate for the given logical bitstream or the entire physical bitstream.


=head2 ov_bitrate_instant

Function returns the average bitrate for the specified logical bitstream. 
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_bitrate_instant.html>

-Input:
  OggVorbis_File.

-Output:
    0 indicates the beginning of the file or unchanged bitrate info.
    OV_EINVAL indicates that an invalid argument value or that the stream represented by vf is not open,
    OV_FALSE means the call returned a 'false' status, 
    n indicates the actual bitrate since the last call.


=head2 ov_serialnumber

serialnumber of the specified logical bitstream link number within the overall physical bitstream.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_serialnumber.html>

-Input:
  OggVorbis_File,
  int (desired logical bitstream)

-Output:
  -1 if the specified logical bitstream i does not exist,
  serial number of the logical bitstream i or the serial number of the current bitstream.


=head2 ov_raw_total

total (compressed) bytes of the physical bitstream or a specified logical bitstream. 
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_raw_total.html>

-Input:
  OggVorbis_File,
  int (desired logical bitstream)

-Output:
  OV_EINVAL means that the argument was invalid
  n total length in compressed bytes of content if i=-1
  n length in compressed bytes of logical bitstream if i=0 to n


=head2 ov_pcm_total

Returns the total pcm samples of the physical bitstream or a specified logical bitstream.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_pcm_total.html>

-Input:
  OggVorbis_File,
  int (desired logical bitstream)

-Output:
  OV_EINVAL means that the argument was invalid
  n total length in pcm samples of content if i=-1
  n length in pcm samples of logical bitstream if i=0 to n


=head2 ov_raw_tell

Returns the current offset in raw compressed bytes.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_raw_tell.html>

-Input:
  OggVorbis_File

-Output:
  n indicates the current offset in bytes,
  OV_EINVAL means that the argument was invalid.


=head2 ov_pcm_tell

Returns the current offset in samples. 
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_pcm_tell.html>

-Input:
  OggVorbis_File

-Output:
  n indicates the current offset in samples,
  OV_EINVAL means that the argument was invalid.


=head2 ov_time_tell

Returns the current decoding offset in seconds.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_time_tell.html>

-Input:
  OggVorbis_File

-Output:
  n indicates the current decoding time offset in seconds,
  OV_EINVAL means that the argument was invalid.


=head2 ov_comment

Returns a pointer to the vorbis_comment struct for the specified bitstream.
L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_comment.html>

-Input:
  OggVorbis_File,
  int (link to desired logical bitstream)

-Output:
  Returns the vorbis_comment struct for the specified bitstream,
  NULL if the specified bitstream does not exist or the file has been initialized improperly.


=head1 Decoding (vorbisfile)

=head2 ov_read

Decode a Vorbis file within a loop. L<http://www.xiph.org/vorbis/doc/vorbisfile/ov_read.html>

-Input:
  OggVorbis_File *vf, 
  char *buffer, 
  int length, 
  int bigendianp, (big or little endian byte packing. 0 for little endian, 1 for b ig endian)
  int word, (word size)
  int sgned, (1 for signed or 0 for unsigned)
  int *bitstream

-Output:
  OV_HOLE, interruption in the data
  OV_EBADLINK, invalid stream section
  OV_EINVAL, initial file headers couldn't be read or are corrupt
  0, EOF
  n, actual number of bytes read


=head2 ov_read_float

B<TODO> Returns samples in native float format instead of in integer formats.


=head2 ov_read_filter

B<TODO> It passes the decoded floating point PCM data to the filter specified in the function arguments before 
converting the data to integer output samples. (variant of ov_read())


=head1 Encoding 


=head2 vorbis_info_init

This function initializes a vorbis_info structure and allocates its internal storage.
L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_info_init.html>

-Input:
  vi, Pointer to a vorbis_info struct to be initialized.

-Output:
  void


=head2 vorbis_encode_init_vbr

This is the primary function within libvorbisenc for setting up variable 
bitrate ("quality" based) modes. 

-Input:
  vorbis_info *vi,
  long channels (number of channels to be encoded),
  long rate (sampling rate of the source audio),
  float base_quality (desired quality level, currently from -0.1 to 1.0 [lo to hi])

-Output:
  0 for success
  less than zero for failure:
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EINVAL - Invalid setup request, eg, out of range argument.
    OV_EIMPL - Unimplemented mode; unable to comply with quality level request.


=head2 vorbis_analysis_init

This function allocates and initializes the encoder's analysis state inside a is 
vorbis_dsp_state, based on the configuration in a vorbis_info struct. 
L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_analysis_init.html>

-Input:
  vorbis_dsp_state *v,
  vorbis_info *vi

-Output:
  0 for SUCCESS


=head2 vorbis_block_init

This function initializes a vorbis_block structure and allocates its internal storage.
L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_block_init.html>

-Input:
  vorbis_dsp_state *v,
  vorbis_block *vb

-Output:
  0 (for success)


=head2 vorbis_encode_setup_init

This function performs the last stage of three-step encoding setup, as 
described in the API overview under managed bitrate modes. 
L<http://xiph.org/vorbis/doc/vorbisenc/vorbis_encode_setup_init.html>

-Input:
  vorbis_info *vi

-Output:
  0 for success
  less than zero for failure:
    OV_EFAULT - Internal logic fault; indicates a bug or heap/stack corruption.
    OV_EINVAL - Attempt to use vorbis_encode_setup_init() without first calling one of vorbis_encode_setup_managed() 
                or vorbis_encode_setup_vbr() to initialize the high-level encoding setup


=head2 vorbis_comment_init

This function initializes a vorbis_comment structure for use.
L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_comment_init.html>

-Input:
  vorbis_comment *vc

-Ouput:
  void


=head2 vorbis_analysis_headerout(v, vc, op, op_comm, op_code)

This function creates and returns the three header packets needed to configure a decoder to 
accept compressed data. L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_analysis_headerout.html>

-Input:
  vorbis_dsp_state *v,
  vorbis_comment *vc,
  ogg_packet *op,
  ogg_packet *op_comm,
  ogg_packet *op_code

-Output:
  0 for success
  negative values for failure:
    OV_EFAULT - Internal fault; indicates a bug or memory corruption.
    OV_EIMPL - Unimplemented; not supported by this version of the library.


=head2 vorbis_analysis_wrote

This function tells the encoder new data is available for compression. 
L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_analysis_wrote.html>

-Input:
  vorbis_dsp_state *v,
  int vals

-Output:  
  0 for success
  negative values for failure:
    OV_EINVAL - Invalid request; e.g. vals overflows the allocated space,
    OV_EFAULT - Internal fault; indicates a bug or memory corruption,
    OV_EIMPL - Unimplemented; not supported by this version of the library.


=head2 vorbis_analysis_blockout

This fuction examines the available uncompressed data and tries to break it into appropriate 
sized blocks. L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_analysis_blockout.html>

-Input:
  vorbis_dsp_state *,
  vorbis_block *

-Output:
  1 for success when more blocks are available.
  0 for success when this is the last block available from the current input.
  negative values for failure:
    OV_EINVAL - Invalid parameters.
    OV_EFAULT - Internal fault; indicates a bug or memory corruption.
    OV_EIMPL - Unimplemented; not supported by this version of the library.


=head2 vorbis_analysis

Once the uncompressed audio data has been divided into blocks, this function is called on each block. 
It looks up the encoding mode and dispatches the block to the forward transform provided by that mode. 
L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_analysis.html>

-Input:
  vorbis_block *,
  ogg_packet *

-Output:
   0 for success
   negative values for failure:
     OV_EINVAL - Invalid request; a non-NULL value was passed for op when the encoder is using a bitrate managed mode.
     OV_EFAULT - Internal fault; indicates a bug or memory corruption.
     OV_EIMPL - Unimplemented; not supported by this version of the library.


=head1 Miscellaneous Functions 

These functions are not found in libvorbis*, but is written by the XS author
to simplify few tasks.


=head2 get_vorbis_info

Returns a HashRef with vorbis_info struct values.
L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_info.html>

-Input:
  vorbis_info

-Output:
  HashRef


=head2 get_vorbis_comment

Returns a HashRef with vorbis_comment struct values.
L<http://www.xiph.org/vorbis/doc/libvorbis/vorbis_comment.html>

-Input:
  vorbis_comment *

-Output:
  HashRef


=head2 vorbis_encode_wav_frames

This function encode the given frames. It calls vorbis_analysis_buffer and
vorbis_analysis_wrote internally to give the data to the encode for compression.

-Input:
  vorbis_dsp_state *,
  int (number of samples to provide space for in the returned buffer),
  channels,
  data buffer

-Output:
  same as of vorbis_analysis_wrote

=head1 CAVEATS

This Modules expects the Theora file to be contained in an Ogg container (which true for most of the vorbis audio
at the time of writing this module). Few of the miscellaneous functions like B<vorbis_encode_wav_frames> are not optimized. 
This module seems to give B<Segmentation Fault> if the version of libvorbis are old. In my system (Mac OS X, 10.5.8) 
when i wrote this module, I was using libvorbis @1.2.3_0 (active) and libogg @1.1.4_0 (active).

=head1 TODO

Decode is supported only via vorbisfile L<www.xiph.org/vorbis/doc/vorbisfile/overview.html>, 
need to add decoding using raw decode functions as mentioned in L<http://www.xiph.org/vorbis/doc/libvorbis/overview.html>

=head1 SEE ALSO

Ogg::LibOgg, L<Ogg::LibOgg>

Vorbis Documentation, L<http://www.xiph.org/vorbis/doc/>

=head1 AUTHOR

Vigith Maurice, E<lt>vigith@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Vigith Maurice, L<www.vigith.com> E<lt>vigith@yahoo-inc.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut

# perl -lne '$/=undef;print $1 while $_ =~ m!(^=head.*?=cut)!msg' LibVorbis.xs | sed -e 's/=cut//' >> lib/Ogg/Vorbis/LibVorbis.pm 
