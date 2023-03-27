package PDL::Demos::OpenCV;
use PDL::OpenCV;

sub info {('opencv', 'OpenCV')}

sub init {'
use PDL::OpenCV;
'}
my @demo = (
[comment => <<'EOF'
    Welcome to a basic demo of the PDL binding of OpenCV.

    It will show you some of its capabilities, especially the famous
    "Hello world" of computer vision: opening up your webcam, and doing
    basic image-processing from it.
EOF
],

[act => q|
# load the modules for this demo
use PDL::LiteF;
use PDL::OpenCV::Videoio;
use PDL::OpenCV::Imgproc;
use PDL::OpenCV::Objdetect;
use PDL::OpenCV::Highgui;
|],

[act => q|
# initialise some objects
$cap = PDL::OpenCV::VideoCapture->new4(0);
$lsd = PDL::OpenCV::LineSegmentDetector->new;
($facedata) = grep -f, map "$_/haarcascades/haarcascade_frontalface_alt.xml",
  qw(/usr/share/opencv4 /usr/local/share/opencv4);
$cc = $facedata ? PDL::OpenCV::CascadeClassifier->new2($facedata) : undef;
|],

[act => q|
print <<'EOF';
Toggles: 'l' lines, 'm' mirror, 'f' face-detection (if Haar cascades found)
'q' in the window quits
EOF
($showlines, $mirror, $face) = (1, 1, 1);
while (1) {
  ($image,$res) = $cap->read;
  last if !$res;
  $image = $image->slice(',-1:0') if $mirror;
  $gray = cvtColor($image, COLOR_BGR2GRAY);
  if ($showlines) {
    ($lines) = $lsd->detect($gray);
    $lsd->drawSegments($image, $lines) if !$lines->isempty;
  }
  if ($cc and $face) {
    ($objects) = $cc->detectMultiScale(equalizeHist($gray));
    rectangle2($image, $objects, [0,255,255,0]); # broadcasting
  }
  imshow 'frame', $image;
  $key = waitKey(1) & 0xFF;
  $showlines = !$showlines if $key == ord 'l';
  $mirror = !$mirror if $key == ord 'm';
  $face = !$face if $key == ord 'f';
  last if $key == ord 'q';
}
destroyWindow 'frame';
waitKey(1); # pump event loop so window actually closes
$cap->release;
|],
);

sub demo { @demo }

1;

=head1 NAME

PDL::Demos::OpenCV - demonstrate PDL::OpenCV capabilities

=head1 SYNOPSIS

  pdl> demo opencv

=cut
