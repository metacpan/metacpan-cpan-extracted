BEGIN { $^W = 1; $| = 1;}
use strict;
use Test;
use Tcl::pTk;


my $mw  = MainWindow->new();
$mw->geometry('+100+100');


if (!$mw->interp->pkg_require('Img')) {
    print "1..0 # skip: no Img extension available ($@)\n";
    exit;
}

plan tests => (2*(7 * 5) + 4);


# Check that the width/height methods work
my $photo = $mw->Photo(-file => 't/Xcamel.gif');
ok($photo->width,  60, "Photo->width method problem");
ok($photo->height, 60, "Photo->height method problem");

my @files = ();

my $row = 0;
foreach my $leaf('Tk.xbm','Xcamel.gif')
 {
  my $file = "./t/$leaf"; #Tk->findINC($leaf);
  my $src = $mw->Photo(-file => $file);
  ok(defined($src),1," Cannot load $file");
  my $kind = 'Initial';
  my $col = 0;
  $mw->Label(-text  => 'Initial')->grid(-row => $row, -column => $col);
  $mw->Label(-background => 'white',-image => $src)->grid(-row => $row+1, -column => $col++);
  $mw->update;

  foreach $kind (qw(bmp gif png jpeg tiff xbm xpm))  # ($src->formats)
   {
    my $f = lc("t/test.$kind");
    my $p = $f;
    push(@files,$f);
    print "$kind - $f\n";
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
    my $width = $new->cget(-height);

   }
 $row += 2;
}

$mw->after(1000,sub{$mw->destroy});
MainLoop;

foreach (@files)
 {
  unlink($_) if -f $_;
 }

