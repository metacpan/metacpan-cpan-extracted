use strict; use warnings;
use Test::More;
use Config;
# Stop f77-linking causing spurious undefined symbols (alpha)
$ENV{'PERL_DL_NONLAZY'}=0 if $Config{'osname'} eq "dec_osf"; 
require PGPLOT;
plan skip_all => 'CI fails with bus error' if $^O eq 'darwin' and $ENV{CI};

my $dev = $ENV{PGPLOT_DEV} || '/NULL';

$ENV{PGPLOT_XW_WIDTH}=0.3;

note "Testing PGPLOT 5.0 colour image routines";

# Read in image (int*2)

my $img="";
open(my $fh,"test.img") || die "Data file test.img not found";
if($^O =~ /mswin32/i) {binmode($fh)}
read($fh, $img, 32768);
close($fh) or die "Can't close test.img: $!";

note length($img)," bytes read";

my @image = unpack("n*",$img);

note $#image+1," element image stored";

PGPLOT::pgbegin(0,$dev,1,1);     # Open plot device 

note "Plotting...";

PGPLOT::pgsci(3);
PGPLOT::pgwnad(12000,13000,13000,12000);

my @tr=(12000,8,0,12000,0,8);

PGPLOT::pgimag(\@image,128,128,1,128,1,128,0,5000,\@tr);
PGPLOT::pglabel("\\ga","\\gd","Galaxy");
PGPLOT::pgtbox("ZYHBCNST",0,0,"ZYDBCNST",0,0);

# Note: pgimag() usually defaults to a grey scale unless you explicitly set
# a colour ramp look-up table with pgctab(). Because it is a look
# up table it can be set after drawing the image. It is best to set an
# explicit LUT as a grey scale default can not be guaranteed on all devices.

# Set PHIL2 colour table

my @l=(0,0.004,0.502,0.941,1); my @r=(0,0,1,1,1); 
my @g=(0,0,0.2,1,1); my @b=(0,0.2,0,0.1,1);

PGPLOT::pgctab(\@l,\@r,\@g,\@b,5,1,0.5);

PGPLOT::pgsci(4); PGPLOT::pgsls(1);
my @cont = (-1,1000,2000,3000,4000,5000);
PGPLOT::pgcons(\@image, 128, 128, 1,128,1,128, \@cont, 6, \@tr);

for(@cont){
   PGPLOT::pgconl(\@image, 128, 128, 1,128,1,128, $_, \@tr, $_,200,100);
}

PGPLOT::pgsci(4); PGPLOT::pgscf(2); 
my (@xbox, @ybox);
PGPLOT::pgqtxt(12125,12100,45,0.5,'PGPLOT...',\@xbox,\@ybox);
PGPLOT::pgpoly(4,\@xbox, \@ybox);
PGPLOT::pgsci(7); 
PGPLOT::pgptxt(12125,12100,45,0.5,'PGPLOT...');

PGPLOT::pgqinf("CURSOR",my $ans,my $l);
if ($ans eq "YES") { for(my $mode=0; $mode<8; $mode++){

   note "Entering interactive PGBAND test MODE=$mode, hit any key, Q to exit early...";

   PGPLOT::pgsci($mode+1);
   PGPLOT::pgband($mode,0,12500,12500,my $x,my $y,my $ch);
   last if $ch eq "q" || $ch eq "Q";
   PGPLOT::pgqtxt($x,$y,45,0.5,'PGPLOT...',\@xbox,\@ybox);
   PGPLOT::pgpoly(4,\@xbox, \@ybox);
   PGPLOT::pgsci($mode+2);
   PGPLOT::pgptxt($x,$y,45,0.5,'PGPLOT...');
   
}}

PGPLOT::pgend();

pass;
done_testing;
