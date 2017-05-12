use Test::More tests => 38;
BEGIN { use_ok('Ogg::Vorbis::LibVorbis'); $|++ };


my $fail = 0;
foreach my $constname (qw(
	INITSET NOTOPEN OPENED OV_EBADHEADER OV_EBADLINK OV_EBADPACKET
	OV_ECTL_IBLOCK_GET OV_ECTL_IBLOCK_SET OV_ECTL_LOWPASS_GET
	OV_ECTL_LOWPASS_SET OV_ECTL_RATEMANAGE2_GET OV_ECTL_RATEMANAGE2_SET
	OV_ECTL_RATEMANAGE_AVG OV_ECTL_RATEMANAGE_GET OV_ECTL_RATEMANAGE_HARD
	OV_ECTL_RATEMANAGE_SET OV_EFAULT OV_EIMPL OV_EINVAL OV_ENOSEEK
	OV_ENOTAUDIO OV_ENOTVORBIS OV_EOF OV_EREAD OV_EVERSION OV_FALSE OV_HOLE
	PARTOPEN STREAMSET)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Ogg::Vorbis::LibVorbis macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );

## END GENERATED ##

# Create Data Structures
my $vf = Ogg::Vorbis::LibVorbis::make_oggvorbis_file(); # OggVorbis_File
ok($vf, "OggVorbis_File");

my $vi = Ogg::Vorbis::LibVorbis::make_vorbis_info(); # vorbis_info
ok($vi, "vorbis_info");

# Open Vorbis File
my $filename = "t/test.ogg";
open IN, $filename or die "can't open [$filename] : $!"; 
my $status = Ogg::Vorbis::LibVorbis::ov_open(*IN,  $vf, 0, 0);
ok($status == 0, "ov_open");

# ov_seekable
$status = Ogg::Vorbis::LibVorbis::ov_seekable($vf);
ok($status != 0, "ov_seekable");

# ov_time_total
$status = Ogg::Vorbis::LibVorbis::ov_time_total($vf, -1);
ok($status > 0, "ov_time_total");

# ov_time_seek
$status = Ogg::Vorbis::LibVorbis::ov_time_seek($vf, 1);
ok($status == 0, "ov_time_seek");

# ov_streams
$status = Ogg::Vorbis::LibVorbis::ov_streams($vf);
ok($status, "ov_streams");

# ov_info
$vi = Ogg::Vorbis::LibVorbis::ov_info($vf, 0); # 0 'coz we know our test .vob file has only 1 bitstream
ok($vi, "ov_info");

# ov_comment
my $vc = Ogg::Vorbis::LibVorbis::ov_comment($vf, 0);
ok($vc, "ov_comment");

# ov_bitrate
$status = Ogg::Vorbis::LibVorbis::ov_bitrate($vf, -1);
ok($status, "ov_bitrate");

# ov_bitrate_instant
$status = Ogg::Vorbis::LibVorbis::ov_bitrate_instant($vf);
ok($status, "ov_bitrate_instant");

# ov_serialnumber
$status = Ogg::Vorbis::LibVorbis::ov_serialnumber($vf, -1);
ok($status, "ov_serialnumber");

# ov_raw_total
$status = Ogg::Vorbis::LibVorbis::ov_raw_total($vf, -1);
ok($status, "ov_raw_total");

# ov_pcm_total
$status = Ogg::Vorbis::LibVorbis::ov_pcm_total($vf, -1);
ok($status, "ov_pcm_total");

# ov_raw_tell
$status = Ogg::Vorbis::LibVorbis::ov_raw_tell($vf);
ok($status, "ov_pcm_tell");

# ov_pcm_tell
$status = Ogg::Vorbis::LibVorbis::ov_pcm_tell($vf);
ok($status, "ov_raw_tell");

# ov_time_tell
$status = Ogg::Vorbis::LibVorbis::ov_time_tell($vf);
ok($status, "ov_time_tell");

$status = Ogg::Vorbis::LibVorbis::get_vorbis_comment($vc);
ok(ref $status eq 'HASH', "get_vorbis_comment");

# get_vorbis_info
$status = Ogg::Vorbis::LibVorbis::get_vorbis_info($vi);
ok ($status->{channels} >= 1, "get_vorbis_info");

# ov_raw_seek
$status = Ogg::Vorbis::LibVorbis::ov_raw_seek($vf, 10);
ok($status == 0, "ov_raw_seek");

# ov_pcm_seek
$status = Ogg::Vorbis::LibVorbis::ov_pcm_seek($vf, 10);
ok($status == 0, "ov_pcm_seek");

# ov_pcm_seek_page
$status = Ogg::Vorbis::LibVorbis::ov_pcm_seek_page($vf, 10);
ok($status == 0, "ov_pcm_seek_page");

# ov_time_seek_page
$status = Ogg::Vorbis::LibVorbis::ov_time_seek_page($vf, 0); # our audio test file is hardly 1 sec :-)
ok($status == 0, "ov_time_seek_page");

# ov_raw_seek_lap
$status = Ogg::Vorbis::LibVorbis::ov_raw_seek_lap($vf, 10); 
ok($status == 0, "ov_raw_seek_lap");

# ov_pcm_seek_lap
$status = Ogg::Vorbis::LibVorbis::ov_pcm_seek_lap($vf, 10); 
ok($status == 0, "ov_pcm_seek_lap");

# ov_time_seek_lap
$status = Ogg::Vorbis::LibVorbis::ov_time_seek_lap($vf, 0); # our audio test file is hardly 1 sec :-)
ok($status == 0, "ov_time_seek_lap");

# ov_pcm_seek_page_lap
$status = Ogg::Vorbis::LibVorbis::ov_pcm_seek_page_lap($vf, 0);
ok($status == 0, "ov_pcm_seek_page_lap");

# ov_time_seek_page_lap
$status = Ogg::Vorbis::LibVorbis::ov_time_seek_page_lap($vf, 0); 
ok($status == 0, "ov_time_seek_page_lap");

# ov_clear
$status = Ogg::Vorbis::LibVorbis::ov_clear($vf);
ok($status == 0, "ov_clear");

# ov_fopen setup
$vf = Ogg::Vorbis::LibVorbis::make_oggvorbis_file(); # OggVorbis_File
# ov_fopen
$status = Ogg::Vorbis::LibVorbis::ov_fopen($filename, $vf);
ok($status == 0, "ov_fopen");
$status = Ogg::Vorbis::LibVorbis::get_vorbis_info($vi);
# ov_clear
$status = Ogg::Vorbis::LibVorbis::ov_clear($vf);

# ov_open_callbacks setup
$vf = Ogg::Vorbis::LibVorbis::make_oggvorbis_file(); # OggVorbis_File
# ov_open_callbacks
open IN, $filename or die "can't open [$filename] : $!"; 
$status = Ogg::Vorbis::LibVorbis::ov_open_callbacks(*IN, $vf, 0, 0);
ok($status == 0, "ov_open_callbacks");
$vi = Ogg::Vorbis::LibVorbis::ov_info($vf, 0);
$status = Ogg::Vorbis::LibVorbis::get_vorbis_info($vi);
# ov_clear
$status = Ogg::Vorbis::LibVorbis::ov_clear($vf);


# ov_test setup
$vf = Ogg::Vorbis::LibVorbis::make_oggvorbis_file(); 
open IN, $filename or die "can't open [$filename] : $!"; 
$status = Ogg::Vorbis::LibVorbis::ov_test(*IN, $vf, 0, 0);
ok($status == 0, "ov_test");
$status = Ogg::Vorbis::LibVorbis::ov_test_open($vf);
ok($status == 0, "ov_test_open");
Ogg::Vorbis::LibVorbis::ov_clear($vf);

# ov_test_callbacks setup
$vf = Ogg::Vorbis::LibVorbis::make_oggvorbis_file(); 
open IN, $filename or die "can't open [$filename] : $!"; 
$status = Ogg::Vorbis::LibVorbis::ov_test_callbacks(*IN, $vf, 0, 0);
ok($status == 0, "ov_test");
$status = Ogg::Vorbis::LibVorbis::ov_test_open($vf);
ok($status == 0, "ov_test_open");
Ogg::Vorbis::LibVorbis::ov_clear($vf);

test_ov_read();
ok(1, "ov_read");

# test ov_read
sub test_ov_read {
  $vf = Ogg::Vorbis::LibVorbis::make_oggvorbis_file(); 
  open IN, $filename or die "can't open [$filename] : $!"; 
  $status = Ogg::Vorbis::LibVorbis::ov_open_callbacks(*IN, $vf, 0, 0);
  my $pcmout = 0;		# i know setting to -1 is of no use, but to avoid warning (_xs_ says NO_INIT)
  my $bit = 0;
  my $ret = -1;
  open OUT, "> t/output.pcm" or die "can't open output.pcm\n";
  binmode OUT;
  my $total = 0;
  while ($ret != 0) {
    $ret = Ogg::Vorbis::LibVorbis::ov_read($vf, $pcmout, 4096, 0, 2, 1, $bit);
    print OUT $pcmout;
  }
  close OUT;
  Ogg::Vorbis::LibVorbis::ov_clear($vf);
  return 
}
