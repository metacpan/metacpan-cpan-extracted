package Ogg::Theora::LibTheora;

use 5.008000;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# This allows declaration	use Ogg::Theora::LibTheora ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw
  (
    OC_BADHEADER
    OC_BADPACKET
    OC_CS_ITU_REC_470BG
    OC_CS_ITU_REC_470M
    OC_CS_NSPACES
    OC_CS_UNSPECIFIED
    OC_DISABLED
    OC_DUPFRAME
    OC_EINVAL
    OC_FAULT
    OC_IMPL
    OC_NEWPACKET
    OC_NOTFORMAT
    OC_PF_420
    OC_PF_422
    OC_PF_444
    OC_PF_RSVD
    OC_VERSION
    TH_CS_ITU_REC_470BG
    TH_CS_ITU_REC_470M
    TH_CS_NSPACES
    TH_CS_UNSPECIFIED
    TH_DECCTL_GET_PPLEVEL_MAX
    TH_DECCTL_SET_GRANPOS
    TH_DECCTL_SET_PPLEVEL
    TH_DECCTL_SET_STRIPE_CB
    TH_DECCTL_SET_TELEMETRY_BITS
    TH_DECCTL_SET_TELEMETRY_MBMODE
    TH_DECCTL_SET_TELEMETRY_MV
    TH_DECCTL_SET_TELEMETRY_QI
    TH_DUPFRAME
    TH_EBADHEADER
    TH_EBADPACKET
    TH_EFAULT
    TH_EIMPL
    TH_EINVAL
    TH_ENCCTL_2PASS_IN
    TH_ENCCTL_2PASS_OUT
    TH_ENCCTL_GET_SPLEVEL
    TH_ENCCTL_GET_SPLEVEL_MAX
    TH_ENCCTL_SET_BITRATE
    TH_ENCCTL_SET_DUP_COUNT
    TH_ENCCTL_SET_HUFFMAN_CODES
    TH_ENCCTL_SET_KEYFRAME_FREQUENCY_FORCE
    TH_ENCCTL_SET_QUALITY
    TH_ENCCTL_SET_QUANT_PARAMS
    TH_ENCCTL_SET_RATE_BUFFER
    TH_ENCCTL_SET_RATE_FLAGS
    TH_ENCCTL_SET_SPLEVEL
    TH_ENCCTL_SET_VP3_COMPATIBLE
    TH_ENOTFORMAT
    TH_EVERSION
    TH_NDCT_TOKENS
    TH_NHUFFMAN_TABLES
    TH_PF_420
    TH_PF_422
    TH_PF_444
    TH_PF_NFORMATS
    TH_PF_RSVD
    TH_RATECTL_CAP_OVERFLOW
    TH_RATECTL_CAP_UNDERFLOW
    TH_RATECTL_DROP_FRAMES
    make_th_info
    make_th_huff_code
    make_th_img_plane
    make_th_quant_info
    make_th_quant_ranges
    make_th_stripe_callback
    make_th_ycbcr_buffer
    make_th_comment
    th_version_number
    th_version_string
    th_packet_isheader
    th_granule_frame
    th_granule_time
    th_packet_iskeyframe
    th_comment_init
    th_info_init
    th_info_clear
    th_comment_add
    th_comment_add_tag
    th_comment_query_count
    th_comment_query
    th_decode_headerin
    th_decode_alloc
    th_setup_free
    th_decode_packetin
    th_decode_ycbcr_out
    th_decode_free
    th_decode_ctl
    th_encode_alloc
    th_encode_flushheader
    th_encode_ycbcr_in
    th_encode_packetout
    th_encode_free
    get_th_info
    ycbcr_to_rgb_buffer
    get_th_comment
    set_th_info
    rgb_th_encode_ycbcr_in
    get_th_ycbcr_buffer_info
    get_th_ycbcr_buffer_data
    get_th_ycbcr_buffer_ptr
 ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

## export only CONSTANTS by default
our @EXPORT = qw(
    OC_BADHEADER
    OC_BADPACKET
    OC_CS_ITU_REC_470BG
    OC_CS_ITU_REC_470M
    OC_CS_NSPACES
    OC_CS_UNSPECIFIED
    OC_DISABLED
    OC_DUPFRAME
    OC_EINVAL
    OC_FAULT
    OC_IMPL
    OC_NEWPACKET
    OC_NOTFORMAT
    OC_PF_420
    OC_PF_422
    OC_PF_444
    OC_PF_RSVD
    OC_VERSION
    TH_CS_ITU_REC_470BG
    TH_CS_ITU_REC_470M
    TH_CS_NSPACES
    TH_CS_UNSPECIFIED
    TH_DECCTL_GET_PPLEVEL_MAX
    TH_DECCTL_SET_GRANPOS
    TH_DECCTL_SET_PPLEVEL
    TH_DECCTL_SET_STRIPE_CB
    TH_DECCTL_SET_TELEMETRY_BITS
    TH_DECCTL_SET_TELEMETRY_MBMODE
    TH_DECCTL_SET_TELEMETRY_MV
    TH_DECCTL_SET_TELEMETRY_QI
    TH_DUPFRAME
    TH_EBADHEADER
    TH_EBADPACKET
    TH_EFAULT
    TH_EIMPL
    TH_EINVAL
    TH_ENCCTL_2PASS_IN
    TH_ENCCTL_2PASS_OUT
    TH_ENCCTL_GET_SPLEVEL
    TH_ENCCTL_GET_SPLEVEL_MAX
    TH_ENCCTL_SET_BITRATE
    TH_ENCCTL_SET_DUP_COUNT
    TH_ENCCTL_SET_HUFFMAN_CODES
    TH_ENCCTL_SET_KEYFRAME_FREQUENCY_FORCE
    TH_ENCCTL_SET_QUALITY
    TH_ENCCTL_SET_QUANT_PARAMS
    TH_ENCCTL_SET_RATE_BUFFER
    TH_ENCCTL_SET_RATE_FLAGS
    TH_ENCCTL_SET_SPLEVEL
    TH_ENCCTL_SET_VP3_COMPATIBLE
    TH_ENOTFORMAT
    TH_EVERSION
    TH_NDCT_TOKENS
    TH_NHUFFMAN_TABLES
    TH_PF_420
    TH_PF_422
    TH_PF_444
    TH_PF_NFORMATS
    TH_PF_RSVD
    TH_RATECTL_CAP_OVERFLOW
    TH_RATECTL_CAP_UNDERFLOW
    TH_RATECTL_DROP_FRAMES
);

our $VERSION = '0.04';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Ogg::Theora::LibTheora::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
      no strict 'refs';
      *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Ogg::Theora::LibTheora', $VERSION);

1;

__END__

# h2xs -n Ogg::Theora::LibTheora -b 5.8.0 theora/codec.h theora/theora.h theora/theoraenc.h theora/theoradec.h

=head1 NAME

Ogg::Theora::LibTheora - XS Interface for calling Theora Video Codec functions in Perl.

=head1 DESCRIPTION

Ogg::Theora::LibTheora is a glue between theora/theora.h theora/theoraenc.h and theora/theoradec.h . 
Please read the XS code to understand the glue implementation.

=head1 SYNOPSIS ENCODE

Encoding raw RGB files to create a theora video file.

  use Ogg::Theora::LibTheora;
  use Ogg::LibOgg ':all';

  my $op = make_ogg_packet();
  my $og = make_ogg_page();
  my $os = make_ogg_stream_state();
  my $oy = make_ogg_sync_state();

  ogg_sync_init($oy); ## should be == 0
  ogg_stream_init($os, 10101); ## should be == 0 and 10101 is a random serial number

  #########################################################################################################
  # (1) Fill in a th_info structure with details on the format of the video you wish to encode.           #
  # (2) Allocate a th_enc_ctx handle with th_encode_alloc().					          #
  # (3) Perform any additional encoder configuration required with th_encode_ctl().		          #
  # (4) Repeatedly call th_encode_flushheader() to retrieve all the header packets.		          #
  # (5) For each uncompressed frame:								          #
  #        (5.a) Submit the uncompressed frame via th_encode_ycbcr_in()				          #
  #        (5.b) Repeatedly call th_encode_packetout() to retrieve any video data packets that are ready. #
  # (6) Call th_encode_free() to release all encoder memory.					          #
  #########################################################################################################

  my $th_setup_info_addr = 0;
  my $th_info = Ogg::Theora::LibTheora::make_th_info();
  Ogg::Theora::LibTheora::th_info_init($th_info);

  my $w = 320;			# width
  my $h = 240;			# height

  Ogg::Theora::LibTheora::set_th_info($th_info, {'frame_width' => $w, 'frame_height' => $h});

  my $th_comment = Ogg::Theora::LibTheora::make_th_comment();
  Ogg::Theora::LibTheora::th_comment_init($th_comment);
  Ogg::Theora::LibTheora::th_comment_add($th_comment, "title=test video");
  Ogg::Theora::LibTheora::th_comment_init($th_comment);

  my $filename = "t/theora_encode.ogg";
  open OUT, ">", "$filename" or die "can't open $filename for writing [$!]";
  binmode OUT;

  my $th_enc_ctx = Ogg::Theora::LibTheora::th_encode_alloc($th_info);

  my $status = 1;
  do {
    $status = Ogg::Theora::LibTheora::th_encode_flushheader($th_enc_ctx, $th_comment, $op);
    if ($status > 0) {
      ogg_stream_packetin($os, $op) == 0 or warn "ogg_stream_packetin returned -1\n"
    } elsif ($status == Ogg::Theora::LibTheora::TH_EFAULT) {
      warn "TH_EFAULT\n"
    }
  } while ($status != 0);

  save_page();

  foreach ((1..5)) {
    add_image("t/enc_pic1.raw");  ## raw files are raw RGB data files
    add_image("t/enc_pic2.raw");
    add_image("t/enc_pic3.raw");
  }

  ogg_stream_flush($os, $og);

  Ogg::Theora::LibTheora::th_encode_free($th_enc_ctx);

  sub save_page {
    ## forms packets to pages 
    if (ogg_stream_pageout($os, $og) != 0) {
      my $h_page = get_ogg_page($og);
      ## writes the header and body 
    } else {
      # pass, we don't have to worry about insufficient data
    }
  }
  
  sub add_image {
    my ($name) = shift;
    open IN, "$name" or die "can't open [$name] $!\n";
    binmode IN;
    local $/ = undef;
    my $str = <IN>;
    close IN;
  
    Ogg::Theora::LibTheora::rgb_th_encode_ycbcr_in($th_enc_ctx, $str, $w, $h) == 0 or warn ("Error th_encode_ycbcr_in");
  
    my $n;
    do {
      $n = Ogg::Theora::LibTheora::th_encode_packetout($th_enc_ctx, 0, $op);
      $n == TH_EFAULT and warn ("($n) TH_EFAULT th_encode_packetout");
    } while (0);
  
    ogg_stream_packetin($os, $op) == 0 or warn ("Internal Error 'ogg_stream_packetin");
  
    save_page();
  }


=head1 SYNOPSIS DECODE

Decoding a theora video file to generate the raw RGB files. (here we generate only 1 raw file)

  use strict;
  use Ogg::LibOgg ':all';

  use Ogg::Theora::LibTheora;


  ## Make Ogg Structures
  my $op = make_ogg_packet();
  my $og = make_ogg_page();
  my $os = make_ogg_stream_state();
  my $oy = make_ogg_sync_state();

  my $filename = "t/theora.ogg";
  open IN, $filename or die "can't open [$filename] : $!";

  ## Ogg Sync Init
  ogg_sync_init($oy);

  ## read a page (wrapper for ogg_sync_pageout)
  ogg_read_page(*IN, $oy, $og);

  my $slno = ogg_page_serialno($og);

  ## Initializes the Ogg Stream State struct
  ogg_stream_init($os, $slno);

  ## add complete page to the bitstream, o create a valid ogg_page struct
  ## after calling ogg_sync_pageout (read_page does ogg_sync_pageout)
  ogg_stream_pagein($os, $og);

  my $th_comment = Ogg::Theora::LibTheora::make_th_comment();
  Ogg::Theora::LibTheora::th_comment_init($th_comment);
  my $th_info = Ogg::Theora::LibTheora::make_th_info();
  Ogg::Theora::LibTheora::th_info_init($th_info);


  ###############################################################################################
  # (1) Parse the header packets by repeatedly calling th_decode_headerin().                    #
  # (2) Allocate a th_dec_ctx handle with th_decode_alloc().                                    #
  # (3) Call th_setup_free() to free any memory used for codec setup information.               #
  # (4) Perform any additional decoder configuration with th_decode_ctl().                      #
  # (5) For each video data packet:                                                             #
  #     (5.a) Submit the packet to the decoder via th_decode_packetin().                        #
  #     (5.b) Retrieve the uncompressed video data via th_decode_ycbcr_out().                   #
  # (6) Call th_decode_free() to release all decoder memory.                                    #
  ###############################################################################################

  ## Decode Header and parse the stream till the first VIDEO packet gets in
  my $th_setup_info_addr = 0;
  my $ret = undef;
  Ogg::Theora::LibTheora::th_packet_isheader($op);
  Ogg::Theora::LibTheora::th_packet_iskeyframe($op);

  do {
    ($ret, $th_setup_info_addr) = Ogg::Theora::LibTheora::th_decode_headerin($th_info, $th_comment, $th_setup_info_addr, $op);
    ## $ret > 0 indicates that a Theora header was successfully processed.
    readPacket() if $ret != 0;
  } while ($ret != 0); ## ret == 0 means, first video data packet was encountered

  ## th_decode_alloc
  my $th_dec_ctx = Ogg::Theora::LibTheora::th_decode_alloc($th_info, $th_setup_info_addr);

  ## th_setup_free
  Ogg::Theora::LibTheora::th_setup_free($th_setup_info_addr);

  ## Make th_ycbcr_buffer
  my $th_ycbcr_buffer = Ogg::Theora::LibTheora::make_th_ycbcr_buffer();


  ## th_decode_packetin
  my $gpos = 0;
  $ret = undef;
  ($ret, $gpos) = Ogg::Theora::LibTheora::th_decode_packetin($th_dec_ctx, $op, $gpos);

  ## th_decode_ycbcr_out
  Ogg::Theora::LibTheora::th_decode_ycbcr_out($th_dec_ctx, $th_ycbcr_buffer);

  my $rgb_buf = Ogg::Theora::LibTheora::ycbcr_to_rgb_buffer($th_ycbcr_buffer);

  open OUT, ">", "t/dec_pic1.raw" or diag( "can't open $!");
  binmode OUT;
  print OUT $rgb_buf;
  close OUT;

  ## th_decode_free
  Ogg::Theora::LibTheora::th_decode_free($th_dec_ctx);

  Ogg::Theora::LibTheora::th_info_clear($th_info);

  close IN;


  sub readPacket {
    while (ogg_stream_packetout($os, $op) == 0) {
      if (not defined ogg_read_page(*IN, $oy, $og)) {
        return undef
      }
      ogg_stream_pagein($os, $og);
    }
  }


=head1 EXPORT

Only constants are exported by DEFAULT

  use Ogg::Theora::LibTheora ':all'; # to export everything to current namespace

=head2 Exportable constants

  OC_BADHEADER
  OC_BADPACKET
  OC_CS_ITU_REC_470BG
  OC_CS_ITU_REC_470M
  OC_CS_NSPACES
  OC_CS_UNSPECIFIED
  OC_DISABLED
  OC_DUPFRAME
  OC_EINVAL
  OC_FAULT
  OC_IMPL
  OC_NEWPACKET
  OC_NOTFORMAT
  OC_PF_420
  OC_PF_422
  OC_PF_444
  OC_PF_RSVD
  OC_VERSION
  TH_CS_ITU_REC_470BG
  TH_CS_ITU_REC_470M
  TH_CS_NSPACES
  TH_CS_UNSPECIFIED
  TH_DECCTL_GET_PPLEVEL_MAX
  TH_DECCTL_SET_GRANPOS
  TH_DECCTL_SET_PPLEVEL
  TH_DECCTL_SET_STRIPE_CB
  TH_DECCTL_SET_TELEMETRY_BITS
  TH_DECCTL_SET_TELEMETRY_MBMODE
  TH_DECCTL_SET_TELEMETRY_MV
  TH_DECCTL_SET_TELEMETRY_QI
  TH_DUPFRAME
  TH_EBADHEADER
  TH_EBADPACKET
  TH_EFAULT
  TH_EIMPL
  TH_EINVAL
  TH_ENCCTL_2PASS_IN
  TH_ENCCTL_2PASS_OUT
  TH_ENCCTL_GET_SPLEVEL
  TH_ENCCTL_GET_SPLEVEL_MAX
  TH_ENCCTL_SET_BITRATE
  TH_ENCCTL_SET_DUP_COUNT
  TH_ENCCTL_SET_HUFFMAN_CODES
  TH_ENCCTL_SET_KEYFRAME_FREQUENCY_FORCE
  TH_ENCCTL_SET_QUALITY
  TH_ENCCTL_SET_QUANT_PARAMS
  TH_ENCCTL_SET_RATE_BUFFER
  TH_ENCCTL_SET_RATE_FLAGS
  TH_ENCCTL_SET_SPLEVEL
  TH_ENCCTL_SET_VP3_COMPATIBLE
  TH_ENOTFORMAT
  TH_EVERSION
  TH_NDCT_TOKENS
  TH_NHUFFMAN_TABLES
  TH_PF_420
  TH_PF_422
  TH_PF_444
  TH_PF_NFORMATS
  TH_PF_RSVD
  TH_RATECTL_CAP_OVERFLOW
  TH_RATECTL_CAP_UNDERFLOW
  TH_RATECTL_DROP_FRAMES

=head1 Functions (malloc)

L<http://www.theora.org/doc/libtheora-1.0/annotated.html>


=head2 make_th_info

Creates a memory allocation for th_info.

-Input:
  Void

-Output:
  Memory Pointer


=head2 make_th_huff_code

Creates a memory allocation for th_huff_code.

-Input:
  void

-Output:
  Memory Pointer


=head2 make_th_img_plane

Creates a memory allocation for th_img_plane.

-Input:
  void

-Output:
  Memory Pointer


=head2 make_th_quant_info

Creates a memory allocation for th_quant_info.

-Input:
  void

-Output:
  Memory Pointer


=head2 make_th_quant_ranges

Creates a memory allocation for th_quant_ranges.

-Input:
  void

-Output:
  Memory Pointer


=head2 make_th_stripe_callback

Creates a memory allocation for th_stripe_callback.

-Input:
  void

-Output:
  Memory Pointer


=head2 make_th_ycbcr_buffer

Creates a memory allocation for th_ycbcr_buffer.

-Input:
  void

-Output:
  Memory Pointer


=head2 make_th_comment

Creates a memory allocation for th_comment.

-Input:
  void

-Output:
  Memory Pointer


=head1 Functions (Basic shared functions)

L<http://www.theora.org/doc/libtheora-1.0/group__basefuncs.html>


=head2 th_version_number

Retrieves the library version number. 

-Input:
  void

-Output:
  ogg_uint32_t (IV)


=head2 th_version_string

Retrieves a human-readable string to identify the library vendor and version. 

-Input:
  void

-Output:
  const char * (T_PV)


=head2 th_packet_isheader

Determines whether a Theora packet is a header or not. 

-Input:
  _op 	An ogg_packet containing encoded Theora data. 

-Output:
  1 packet is a header packet,
  0 packet is a video data packet. 


=head2 th_granule_frame

Converts a granule position to an absolute frame index, starting at 0. 

-Input:
  void * _encdec (previously allocated th_enc_ctx or th_dec_ctx handle),
  ogg_int64_t _granpos (granule position to convert).

-Output:
  absolute frame index corresponding to _granpos,
  -1 on error.


=head2 th_granule_time

Converts a granule position to an absolute time in seconds. 

-Input:
  void * _encdec (previously allocated th_enc_ctx or th_dec_ctx handle),
  ogg_int64_t _granpos (granule position to convert).

-Output:
  absolute time in seconds corresponding to _granpos,
  -1 on error.


=head2 th_packet_iskeyframe

Determines whether a theora packet is a key frame or not. 

-Input:
  _op 	An ogg_packet containing encoded Theora data. 

-Output:
   1 packet is a key frame,
   0 packet is a delta frame,
  -1 packet is not a video data packet. 


=head1 Functions (Manipulating Header Data)


=head2 th_comment_init

Initialize a th_comment structure. 

-Input:
  th_comment *

-Output:
  void


=head2 th_info_init

Initializes a th_info structure. 

-Input:
  th_info

-Output:
  void


=head2 th_info_clear

Clears a th_info structure. 

-Input:
  th_info

-Output:
  void


=head2 th_comment_add

Add a comment to an initialized th_comment structure. 

-Input:
  th_comment,
  char * (null-terminated UTF-8 string containing the comment in "TAG=the value" form).

-Output:
  void


=head2 th_comment_add_tag

Add a comment to an initialized th_comment structure. 

-Input:
  th_comment,
  char * (null-terminated string containing the tag associated with the comment),
  char * (corresponding value as a null-terminated string).


=head2 th_comment_query_count

Look up the number of instances of a tag.

-Input:
  th_comment,
  char * (tag to look up).

-Output:
  int (number on instances of this particular tag)


=head2 th_comment_query

Look up a comment value by its tag. 

-Input:
  th_comment,
  char * (tag to look-up)
  int (instance of the tag, it starts from 0)

-Output:
  char * if matched pointer to the queried tag's value,
  NULL if no matching tag is found


=head1 Functions (For Decoding)

L<http://www.theora.org/doc/libtheora-1.0/group__decfuncs.html>


=head2 th_decode_headerin

Decodes the header packets of a Theora stream. 

-Input:
  th_info,
  th_comment,
  th_setup_info, (initialized to NULL on the first call & returned value be passed on subsequent calls)
  ogg_packet

-Output:
  0 first video data packet was encountered after all required header packets were parsed,
  TH_EFAULT if one of _info, _tc, or _setup was NULL,
  TH_EBADHEADER _op was NULL,
  TH_EVERSION not decodable with current libtheoradec version,
  TH_ENOTFORMAT not a Theora header


=head2 th_decode_alloc

Allocates a decoder instance. 

-Input:
  th_info,
  th_setup_info

-Output:
  th_dec_ctx


=head2 th_setup_free

Releases all storage used for the decoder setup information.

-Input:
  th_setup_info

-Output:
  void


=head2 th_decode_packetin

Submits a packet containing encoded video data to the decoder. 

-Input:
  th_dec_ctx,
  ogg_packet,
  ogg_int64_t gran_pos, returns the granule position of the decoded packet

-Output:
  0 success,
  TH_DUPFRAME packet represented a dropped (0-byte) frame,
  TH_EFAULT _dec or _op was NULL,
  TH_EBADPACKET _op does not contain encoded video data,
  TH_EIMPL video data uses bitstream features which this library does not support.


=head2 th_decode_ycbcr_out

Outputs the next available frame of decoded Y'CbCr data. 

-Input:
  th_dec_ctx,
  th_ycbcr_buffer (video buffer structure to fill in)

-Output:
  0 Success


=head2 th_decode_free

Frees an allocated decoder instance. 

-Input:
  th_dec_ctx

-Output:
  void


=head2 th_decode_ctl

Decoder control function. (i haven't tested this)

-Input:
  th_dec_ctx,
  int _req (control code to process),
  void * _buf (parameters for this control code),
  size_t _buf_sz (size of the parameter buffer)

-Output:
  int (not documented)


=head1 Functions (for Encoding)

L<http://www.theora.org/doc/libtheora-1.0/group__encfuncs.html>


=head2 th_encode_alloc

Allocates an encoder instance.

-Input:
  th_info.

-Output:
  th_enc_ctx handle,
  NULL (if the encoding parameters were invalid).


=head2 th_encode_flushheader

-Input:
  th_enc_ctx,
  th_comment,
  ogg_packet.

-Output:
  > 1 (indicates that a header packet was successfully produced),
  0 (no packet was produced, and no more header packets remain),
  TH_EFAULT (_enc, _comments, or _op was NULL).


=head2 th_encode_ycbcr_in

Submits an uncompressed frame to the encoder. (if you don't have ycbcr buffer
you can try using the *unoptimized* rgb_th_encode_ycbcr_in, better you write 
your own).

-Input:
  th_enc_ctx,
  th_ycbcr_buffer

-Output:
  0 Success,
  TH_EFAULT _enc or _ycbcr is NULL,
  TH_EINVAL buffer size does not match the frame size encoder was initialized.


=head2 th_encode_packetout

Retrieves encoded video data packets. 

-Input:
  th_enc_ctx,
  int (non-zero value if no more uncompressed frames will be submitted),
  ogg_packet.

-Output:
  > 0 a video data packet was successfully produced,
    0 no packet was produced, and no more encoded video data remains,
  TH_EFAULT _enc or _op was NULL.


=head2 th_encode_free

Frees an allocated encoder instance. 

-Input:
  th_enc_ctx

-Output:
  void


=head1 Miscellaneous Functions 

These functions are not found in libtheora*, but is written by the XS author
to simplify few tasks.


=head2 get_th_info

Returns a HashRef with th_info struct values.

-Input:
  th_info

-Output:
  HashRef


=head2 ycbcr_to_rgb_buffer

reads the data from the ycbcr buffer and converts to its equivalent
rgb buffer. (this is NOT an optimized code, there will be better ycbcr
to rgb convertors, some intel gpu processors have mnemonic that does
the conversion)

-Input:
   th_ycbcr_buffer

-Output:
  RGB string


=head2 get_th_comment

return an array of comments

-Input:
  th_comment

-Output:
  array of comments


=head2 set_th_info

sets the th_info structure to default values unless specified in hash. frame_width and frame_height
is mandatory.

-Input:
  Hash of elements

-Output:
  void


=head2 rgb_th_encode_ycbcr_in

Converts a rgb to ycbcr buffer. (this is not an optimized code)

-Input:
  th_enc_ctx
  char * (rgb string),
  width,
  height.

-Output:
  th_ycbcr_buffer


=head2 get_th_ycbcr_buffer_info

Returns an arrayref of hashrefs containing width, height, stride
and data_pointer for each plane (issue#1)

-Input:
  th_ycbcr_buffer

-Output:
  arrayref

=head2 get_th_ycbcr_buffer_ptr

Returns an data pointer for specified plane index (0 - Y, 1 - Cb, 2 - Cr)

-Input:
  th_ycbcr_buffer
  index

-Output:
  pointer

=head2 get_th_ycbcr_buffer_data

Returns an data for specified plane index (0 - Y, 1 - Cb, 2 - Cr)

-Input:
  th_ycbcr_buffer
  index

-Output:
  string - use unpack to get numbers

=head1 CAVEATS

This Modules expects the Theora file to be contained in an Ogg container (which true for most of the theora videos
at the time of writing this module). Few of the miscellaneous functions like B<rgb_th_encode_ycbcr_in>, 
B<ycbcr_to_rgb_buffer> are not optimized. This module seems to give B<Segmentation Fault> if the version of libtheora
is pre-1.0. In my system (Mac OS X, 10.5.8) when i wrote this module, I was using libtheora @1.1.1_0 (active)
and libogg @1.1.4_0 (active).

=head1 SEE ALSO

Ogg::LibOgg, L<Ogg::LibOgg>

Theora Documentation, L<http://www.theora.org/doc/libtheora-1.0/>

You can find the code for this module and few examples at L<https://github.com/vigith/Ogg-Theora-LibTheora>

=head1 AUTHOR

Vigith Maurice, E<lt>vigith@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011,2012 by Vigith Maurice, L<www.vigith.com> E<lt>vigith@cpan.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut

#perl -lne '$/=undef;print $1 while $_ =~ m!(^=head.*?=cut)!msg' LibTheora.xs | sed -e 's/=cut//' >> lib/Ogg/Theora/LibTheora.pm 
