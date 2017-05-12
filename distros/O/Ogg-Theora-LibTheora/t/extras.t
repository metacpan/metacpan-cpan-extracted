
use strict;
use Ogg::LibOgg ':all';

use Test::More tests => 26;
BEGIN { 
  use_ok('Ogg::Theora::LibTheora')
};


my $fail = 0;
foreach my $constname (qw(
	OC_BADHEADER OC_BADPACKET OC_CS_ITU_REC_470BG OC_CS_ITU_REC_470M
	OC_CS_NSPACES OC_CS_UNSPECIFIED OC_DISABLED OC_DUPFRAME OC_EINVAL
	OC_FAULT OC_IMPL OC_NEWPACKET OC_NOTFORMAT OC_PF_420 OC_PF_422
	OC_PF_444 OC_PF_RSVD OC_VERSION TH_CS_ITU_REC_470BG TH_CS_ITU_REC_470M
	TH_CS_NSPACES TH_CS_UNSPECIFIED TH_DECCTL_GET_PPLEVEL_MAX
	TH_DECCTL_SET_GRANPOS TH_DECCTL_SET_PPLEVEL TH_DECCTL_SET_STRIPE_CB
	TH_DECCTL_SET_TELEMETRY_BITS TH_DECCTL_SET_TELEMETRY_MBMODE
	TH_DECCTL_SET_TELEMETRY_MV TH_DECCTL_SET_TELEMETRY_QI TH_DUPFRAME
	TH_EBADHEADER TH_EBADPACKET TH_EFAULT TH_EIMPL TH_EINVAL
	TH_ENCCTL_2PASS_IN TH_ENCCTL_2PASS_OUT TH_ENCCTL_GET_SPLEVEL
	TH_ENCCTL_GET_SPLEVEL_MAX TH_ENCCTL_SET_BITRATE TH_ENCCTL_SET_DUP_COUNT
	TH_ENCCTL_SET_HUFFMAN_CODES TH_ENCCTL_SET_KEYFRAME_FREQUENCY_FORCE
	TH_ENCCTL_SET_QUALITY TH_ENCCTL_SET_QUANT_PARAMS
	TH_ENCCTL_SET_RATE_BUFFER TH_ENCCTL_SET_RATE_FLAGS
	TH_ENCCTL_SET_SPLEVEL TH_ENCCTL_SET_VP3_COMPATIBLE TH_ENOTFORMAT
	TH_EVERSION TH_NDCT_TOKENS TH_NHUFFMAN_TABLES TH_PF_420 TH_PF_422
	TH_PF_444 TH_PF_NFORMATS TH_PF_RSVD TH_RATECTL_CAP_OVERFLOW
	TH_RATECTL_CAP_UNDERFLOW TH_RATECTL_DROP_FRAMES)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Ogg::Theora::LibTheora macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################



## Make Ogg Structures
my $op = make_ogg_packet();
my $og = make_ogg_page();
my $os = make_ogg_stream_state();
my $oy = make_ogg_sync_state();

ok($op != 0, 'make_ogg_packet');
ok($og != 0, 'make_ogg_page');
ok($os != 0, 'make_ogg_stream_state');
ok($oy != 0, 'make_ogg_sync_state');


## Make th_info
my $th_info = Ogg::Theora::LibTheora::make_th_info();
ok($th_info != 0, "Make th_info");

Ogg::Theora::LibTheora::th_info_init($th_info);
ok(1, "th_info_init");

## Make th_huff_code
my $th_huff_code = Ogg::Theora::LibTheora::make_th_huff_code();
ok($th_huff_code != 0, "Make th_huff_code");

## Make th_img_plane
my $th_img_plane = Ogg::Theora::LibTheora::make_th_img_plane();
ok($th_img_plane != 0, "Make th_img_plane");

## Make th_quant_info
my $th_quant_info = Ogg::Theora::LibTheora::make_th_quant_info();
ok($th_quant_info != 0, "Make th_quant_info");

## Make th_quant_ranges
my $th_quant_ranges = Ogg::Theora::LibTheora::make_th_quant_ranges();
ok($th_quant_ranges != 0, "Make th_quant_ranges");

## Make th_stripe_callback
my $th_stripe_callback = Ogg::Theora::LibTheora::make_th_stripe_callback();
ok($th_stripe_callback != 0, "Make th_stripe_callback");

## Make th_ycbcr_buffer
my $th_ycbcr_buffer = Ogg::Theora::LibTheora::make_th_ycbcr_buffer();
ok($th_ycbcr_buffer != 0, "Make th_ycbcr_buffer");

## th_version_number
ok(Ogg::Theora::LibTheora::th_version_number() != 0, "th_version_number");

## th_version_string
ok(Ogg::Theora::LibTheora::th_version_string ne '', "th_version_string");

## th_comment
my $th_comment = Ogg::Theora::LibTheora::make_th_comment();
ok($th_comment != 0, "th_comment");

## th_comment_init
Ogg::Theora::LibTheora::th_comment_init($th_comment);
ok(1, "th_comment_init"); 

Ogg::Theora::LibTheora::th_comment_add($th_comment, "myname=vigith maurice");
my @arr = Ogg::Theora::LibTheora::get_th_comment($th_comment);
ok(scalar (@arr) == 1, "th_comment_add");
ok(1, "get_th_comment");

Ogg::Theora::LibTheora::th_comment_add_tag($th_comment, "fname", "vigith");
@arr = Ogg::Theora::LibTheora::get_th_comment($th_comment);
ok(grep (m!fname=!, @arr) == 1, 'th_comment_add_tag');

my $count = Ogg::Theora::LibTheora::th_comment_query_count($th_comment, "fname");
ok($count == 1, 'th_comment_query_count');

ok(Ogg::Theora::LibTheora::th_comment_query($th_comment, "fname", 0) eq 'vigith', "th_comment_query");
is(Ogg::Theora::LibTheora::th_comment_query($th_comment, "fname", 1), undef, "th_comment_query");

Ogg::Theora::LibTheora::set_th_info($th_info, {'frame_width' => 300, 'frame_height' => 500});
my $h_info = Ogg::Theora::LibTheora::get_th_info($th_info);
ok($h_info->{frame_height} == 500 && $h_info->{frame_width} == 300, 'set_th_info');

## is_header
ok(Ogg::Theora::LibTheora::th_packet_isheader($op) >= 0, "th_packet_isheader");

