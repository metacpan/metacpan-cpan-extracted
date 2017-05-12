# Test script for the Photo widget as a subclass of Image

BEGIN { $^W = 1; $| = 1;}
use strict;
use Test;
use Tcl::pTk;
#use Tcl::pTk::Photo;
#use Tk;

my $mw  = MainWindow->new();
$mw->geometry('+100+100');

# This will skip if Tix not present
my $imagePresent = $mw->interp->pkg_require('Img');


plan tests => 7;


# Check that the width/height methods work
my $photo = $mw->Photo(-file => 't/Xcamel.gif');
ok($photo->width,  60, "Photo->width method problem");
ok($photo->height, 60, "Photo->height method problem");

my $label = $mw->Label(-image => $photo)->pack();

# Check to see if retreived photo works
my $image = $label->cget(-image);
ok($image->width,  60, "Photo->width method problem");
ok($photo->height, 60, "Photo->height method problem");

my $type = $image->type();
ok($type, 'photo', 'Unexpected type');

# Make sure image names returns a Photo object.
my @names = $mw->imageNames();
#print "Names = ".join(", ", @names)."\n";
ok(ref($names[0]) =~ /Photo/i); # Check for image name being a image object

my @types = $mw->imageTypes;
#print "imageTypes = ".join(", ", @types)."\n";
my @expectedTypes = (qw/ Bitmap Photo Pixmap/);
pop @expectedTypes unless( $imagePresent ); # Pixmap won't be there if Img package not there
ok(join(", ", sort @types), join(", ", sort @expectedTypes), "Unexpected imageTypes");

# Delete the image after a second
$mw->after(1000, sub{ $image->delete });

$mw->after(2000,sub{$mw->destroy});
MainLoop;


