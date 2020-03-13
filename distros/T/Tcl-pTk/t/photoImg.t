BEGIN { $| = 1;}
use warnings;
use strict;
use Test;
use Tcl::pTk;


# Test image formats supported by TkImg extension
# (similar to photo.t in Perl/Tk and Tcl::pTk < 0.95)

my %images = (
    'Tk.xbm' => 'xbm',
    'Xcamel.gif' => 'gif',
);
my $image_count = keys %images;

# Formats supported by TkImg
my @kinds_supported = (
    'gif',
    'ppm',
    'bmp',
    'jpeg',
    'png',
    'tiff',
    'xbm',
    'xpm',
);
my $kind_count = scalar @kinds_supported;

my $mw  = MainWindow->new();
$mw->geometry('+100+100');

my $Img_version = $mw->interp->pkg_require('Img');
unless ($Img_version) {
    print "1..0 # Skipped: Tk Img extension not found\n";
    $mw->destroy;
    exit;
}

plan tests => ($image_count*($kind_count * 5 + 1) + 2);

# Check that the width/height methods work
my $photo = $mw->Photo(-file => 't/Xcamel.gif');
ok($photo->width,  60, "Photo->width method problem");
ok($photo->height, 60, "Photo->height method problem");

my @files = ();

my $row = 0;
foreach my $leaf (sort keys %images) {
    my $file = "./t/$leaf"; #Tk->findINC($leaf);
    my $src = $mw->Photo(-file => $file);
    ok(defined($src),1," Cannot load $file");
    my $kind = 'Initial';
    my $col = 0;
    $mw->Label(-text  => 'Initial')->grid(-row => $row, -column => $col);
    $mw->Label(-background => 'white',-image => $src)->grid(-row => $row+1, -column => $col++);
    $mw->update;

    foreach $kind (@kinds_supported)  # ($src->formats)
    {
        my $f = lc("t/test.$kind");
        my $p = $f;
        print "# $kind - $f\n";
        push(@files,$f);
        eval { $src->write($f, -format => "$kind") };
        ok($@,''," write $@");
        ok($p,$f,"File name corrupted");
        ok(-f $f,1,"No $f created");
        my $new;
        eval { $new = $mw->Photo(-file => $f, -format => "$kind") };
        ok($@,''," load $@");
        ok(defined($new),1,"Could not load $f");
        $mw->Label(-text  => $kind)->grid(-row => $row, -column => $col);
        $mw->Label(-background => 'white', -image => $new)->grid(-row => $row+1, -column => $col++);
        $mw->update;
    }
    $row += 2;
}

$mw->idletasks;
(@ARGV) ? MainLoop : $mw->destroy;

foreach (@files)
 {
  unlink($_) if -f $_;
 }

