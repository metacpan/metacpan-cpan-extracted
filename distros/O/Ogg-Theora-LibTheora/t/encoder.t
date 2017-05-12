
use strict;
use Ogg::LibOgg ':all';

use Test::More tests => 14;
BEGIN { 
  use_ok('Ogg::Theora::LibTheora') 
};


## Make Ogg Structures
my $op = make_ogg_packet();
my $og = make_ogg_page();
my $os = make_ogg_stream_state();
my $oy = make_ogg_sync_state();

ok($op != 0, 'make_ogg_packet');
ok($og != 0, 'make_ogg_page');
ok($os != 0, 'make_ogg_stream_state');
ok($oy != 0, 'make_ogg_sync_state');

## Ogg Sync Init
ok(ogg_sync_init($oy) == 0, "ogg_sync_init");

## Initializes the Ogg Stream State struct
ok(ogg_stream_init($os, 10101) == 0, "ogg_stream_init");


#########################################################################################################
# (1) Fill in a th_info structure with details on the format of the video you wish to encode.	        #
# (2) Allocate a th_enc_ctx handle with th_encode_alloc().					        #
# (3) Perform any additional encoder configuration required with th_encode_ctl().		        #
# (4) Repeatedly call th_encode_flushheader() to retrieve all the header packets.		        #
# (5) For each uncompressed frame:								        #
#        (5.a) Submit the uncompressed frame via th_encode_ycbcr_in()				        #
#        (5.b) Repeatedly call th_encode_packetout() to retrieve any video data packets that are ready. #
# (6) Call th_encode_free() to release all encoder memory.					        #
#########################################################################################################
  

## (1) ##

my $th_setup_info_addr = 0;
my $th_info = Ogg::Theora::LibTheora::make_th_info();

Ogg::Theora::LibTheora::th_info_init($th_info);
ok(1, 'th_info_init');

my $w = 320;			# width
my $h = 240;			# height

Ogg::Theora::LibTheora::set_th_info($th_info, {'frame_width' => $w, 'frame_height' => $h});

my $th_comment = Ogg::Theora::LibTheora::make_th_comment();

Ogg::Theora::LibTheora::th_comment_init($th_comment);
ok(1, "th_comment_init");

Ogg::Theora::LibTheora::th_comment_add($th_comment, "title=test video");

Ogg::Theora::LibTheora::th_comment_init($th_comment);

my $filename = "t/theora_encode.ogg";
open OUT, ">", "$filename" or die "can't open $filename for writing [$!]";
binmode OUT;


## (2) ##

my $th_enc_ctx = Ogg::Theora::LibTheora::th_encode_alloc($th_info);
ok($th_enc_ctx != 0, 'th_encode_alloc');

## (3) ##

## None

## (4) ##

my $status = 1;
do {
  $status = Ogg::Theora::LibTheora::th_encode_flushheader($th_enc_ctx, $th_comment, $op);
  if ($status > 0) {
    ogg_stream_packetin($os, $op) == 0 or warn "ogg_stream_packetin returned -1\n"
  } elsif ($status == Ogg::Theora::LibTheora::TH_EFAULT) {
    warn "TH_EFAULT\n"
  }
} while ($status != 0);

ok(1, 'th_encode_flushheader');

save_page();
ok(1, 'save page');


foreach ((1..5)) {
  add_image("t/enc_pic1.raw");
  add_image("t/enc_pic2.raw");
  add_image("t/enc_pic3.raw");
}
ok(1, 'th_encode_packetout');

ogg_stream_flush($os, $og);


## CLEANUPS ##

is(Ogg::Theora::LibTheora::th_encode_free($th_enc_ctx), undef, 'th_encode_free');

close OUT;

# let the file be kept, size is quite small
# unlink $filename or die("can't remove $filename [$!]");


################
# SUB ROUTINES #
################


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

sub add_image {
  my ($name) = shift;
  open IN, "$name";
  binmode IN;
  local $/ = undef;
  my $str = <IN>;
  close IN;

  Ogg::Theora::LibTheora::rgb_th_encode_ycbcr_in($th_enc_ctx, $str, $w, $h) == 0 or diag ("Error rbg_th_encode_ycbcr_in");

  my $n;
  do {
    $n = Ogg::Theora::LibTheora::th_encode_packetout($th_enc_ctx, 0, $op);
    $n == TH_EFAULT and diag ("($n) TH_EFAULT th_encode_packetout");
  } while (0);

  ogg_stream_packetin($os, $op) == 0 or diag ("Internal Error 'ogg_stream_packetin");

  save_page();
}
