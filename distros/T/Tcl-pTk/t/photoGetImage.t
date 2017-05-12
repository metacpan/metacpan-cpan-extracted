BEGIN { $^W = 1; $| = 1;}
use strict;
use Test;
use Tcl::pTk;


# This test case checks for a particular bug (fixed 4/9/09) where loading a image using Getimage would cause
#   subsequent Photo image creations to result in invalid images. Root cause appeared to be that Getimage
#   does a "package require img:xpm", where Photo does a "package require Img", which appeared to be incompatible.

my $mw  = MainWindow->new();
$mw->geometry('+100+100');

my $folder = $mw->Getimage('folder');

if (!$mw->interp->pkg_require('Img')) {
    print "1..0 # skip: no Img extension available ($@)\n";
    exit;
}

plan tests => 2;

my $imagefile = Tcl::pTk->findINC('srcfile.xpm');
#print STDERR "imagefile = $imagefile\n";
my $photo = $mw->Photo(-file => $imagefile, -width => 0, -height => 0 );

# Check that the width/height methods work
ok($photo->width,  12, "Photo->width method problem");
ok($photo->height, 12, "Photo->height method problem");



