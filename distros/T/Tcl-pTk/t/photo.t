BEGIN { $| = 1;}
use warnings;
use strict;
use Test;
use Tcl::pTk;


my %images = (
    'Tk.xbm' => 'xbm',
    'Xcamel.gif' => 'gif'
);
my $image_count = keys %images;

# Formats supported by Tk 8.4-8.5 without extensions
my %kind_is_supported = (
    'gif'  => 1,
    'ppm'  => 1,
    'bmp'  => 0,
    'jpeg' => 0,
    'png'  => 0,
    'tiff' => 0,
    'xbm'  => 0,
    'xpm'  => 0,
);
my $kind_count = keys %kind_is_supported;

plan tests => ($image_count*($kind_count * 5 + 1) + 2);

my $mw  = MainWindow->new();
$mw->geometry('+100+100');

my $Img_version = $mw->interp->pkg_require('Img');
if ($Img_version) {
    # Add formats supported by Img extension
    foreach my $kind (qw(bmp jpeg png tiff xbm xpm)){
        $kind_is_supported{$kind} = 1;
    }
} elsif (
    ($mw->interp->Eval('package vcompare $tk_version 8.6') != -1)
    or $mw->interp->pkg_require('tkpng')
) {
    # Add png (supported by TkPNG or Tk 8.6+)
    $kind_is_supported{'png'} = 1;
}

# Say whether PNG is supported first
# since there are multiple ways to support it…
if (not $kind_is_supported{'png'}) {
    print "# PNG support not found (requires Img, TkPNG, or Tk 8.6+).\n"
        . "# PNG tests will be skipped.\n";
}
# …then say whether Img is present
# (without needing to mention PNG again) 
if (not $Img_version) {
    print "# Tk Img extension not found.\n"
        . "# BMP, JPEG, TIFF, XBM, and XPM tests will be skipped.\n";
}

# Check that the width/height methods work
my $photo = $mw->Photo(-file => 't/Xcamel.gif');
ok($photo->width,  60, "Photo->width method problem");
ok($photo->height, 60, "Photo->height method problem");

my @files = ();

my $row = 0;
foreach my $leaf (sort keys %images) {
    # Check that the format of the input image is supported 
    if (not $kind_is_supported{$images{$leaf}}) {
        for (1..($kind_count * 5 + 1)) {
            skip uc($images{$leaf}) . " support not found (needed for $leaf)";
        }
    } else {
        my $file = "./t/$leaf"; #Tk->findINC($leaf);
        my $src = $mw->Photo(-file => $file);
        ok(defined($src),1," Cannot load $file");
        my $kind = 'Initial';
        my $col = 0;
        $mw->Label(-text  => 'Initial')->grid(-row => $row, -column => $col);
        $mw->Label(-background => 'white',-image => $src)->grid(-row => $row+1, -column => $col++);
        $mw->update;

        foreach $kind (sort keys %kind_is_supported)  # ($src->formats)
        {
            my $f = lc("t/test.$kind");
            my $p = $f;
            print "# $kind - $f\n";
            # Check that outputting to $kind is supported
            if (not $kind_is_supported{$kind}) {
                for (1..5) {
                    skip uc($kind) . ' support not found';
                }
            } else {
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
        }
        $row += 2;
    }
}

$mw->idletasks;
MainLoop if (@ARGV);

foreach (@files)
 {
  unlink($_) if -f $_;
 }

