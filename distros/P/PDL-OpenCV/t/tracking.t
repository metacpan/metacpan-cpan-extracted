use strict;
use warnings;
use Test::More;
use PDL::LiteF;
use PDL::OpenCV;
use PDL::OpenCV::Highgui;
use PDL::OpenCV::Imgproc;
use PDL::OpenCV::Tracking;
use PDL::OpenCV::Videoio;
use PDL::OpenCV::Objdetect;

{
  my $imgb = zeroes 3,500,500;
  for (1..2) {
    my $cpy = $imgb->copy;
    my ($pts) = ellipse2Poly([250,250],[200,100],45,60,120+$_,1);
    rectangle($cpy, $_, $_+1, [255,0,0,0]) for $pts->dog;
    imshow("ud", $cpy), waitKey(300) if $ENV{AUTHOR_TESTING};
  }
}

my $cc = PDL::OpenCV::CascadeClassifier->new;
my $CC_DIR = '';
my ($loaded) = $cc->load($CC_DIR.'/haarcascades/haarcascade_frontalface_alt.xml') if $CC_DIR;
die "Failed to load" if $CC_DIR and !$loaded;

my $vfile='t/frames.avi';
my $vc = PDL::OpenCV::VideoCapture->new;
die if !$vc->open($vfile, CAP_ANY);
isnt $vc->getBackendName, undef, 'getBackendName works';
my ($frame, $res) = $vc->read;
ok $res, 'read a frame right';
is_deeply [$frame->dims], [3,720,528], 'right dims' or diag $frame->info;

is my $fcc = PDL::OpenCV::VideoWriter::fourcc(split '', 'MP4V'), 1446269005, 'fourcc right value';

my $box=pdl(qw/240 161 187 202/);
my $tr = PDL::OpenCV::TrackerKCF->new;
if ($ENV{AUTHOR_TESTING} && $box->at(0) == 0) {
  namedWindow("ud",WINDOW_NORMAL);
  $box = selectROI("ud",$frame,1,0);
  destroyWindow("ud");
}
$box = $tr->init(frame_scale($frame),$box);

my $lsd = PDL::OpenCV::LineSegmentDetector->new(LSD_REFINE_STD);

my $x = 0;
while ($res) {
  ($box, my $track_res) = $tr->update($frame = frame_scale($frame));
  my ($lines) = $lsd->detect(my $gray = cvtColor($frame, COLOR_BGR2GRAY));
  my ($binary) = threshold($gray, 127, 255, 0);
  my ($contours) = findContours($binary,RETR_TREE,CHAIN_APPROX_SIMPLE,[0,0]);
  rectangle2($frame, $box, [255,0,0,0]);
  drawContours($frame,$contours,-1,[0,255,0,0]);
  $lsd->drawSegments($frame, $lines);
  if ($CC_DIR) {
    my ($objects) = $cc->detectMultiScale(equalizeHist($gray));
    rectangle2($frame, $objects, [0,255,255,0]); # broadcasting
  }
  imshow("ud", $frame), waitKey(300) if $ENV{AUTHOR_TESTING};
  if ((int($x/2) % 2) == 0) {
          is(all ($box) >0,1,"tracker found box $x.");
          ok $track_res, 'tracker said found';
  } else {
          is(all ($box) == 0,1,"tracker did not find box $x.");
          ok !$track_res, 'tracker said not found';
  }
  note "x $x box $box";
  ($frame, $res) = $vc->read;
  $x++;
}

done_testing();

sub frame_scale {
  my ($frame) = @_;
  my ($min, $max) = PDL::OpenCV::minMaxLoc($frame->clump(2)->dummy(0));
  $frame = ($frame * (255/$max))->byte if $max->sclr != 255;
  $frame->dim(0) == 1 ? cvtColor($frame, COLOR_GRAY2RGB) : $frame;
}
