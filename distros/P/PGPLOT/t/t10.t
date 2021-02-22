use strict; use warnings;
use Test::More;
use Config;
# Stop f77-linking causing spurious undefined symbols (alpha)
$ENV{'PERL_DL_NONLAZY'}=0 if $Config{'osname'} eq "dec_osf";
require PGPLOT;

my $dev = $ENV{PGPLOT_DEV} || '/NULL';

$ENV{PGPLOT_XW_WIDTH}=0.3;

note "Testing multiple ways of passing things";

# Create 138x128 image - note must use transpose as
# perl is column major like C (see docs)

my $k=0;
my (@img1D, @img2D);
for(my $i=0; $i<128; $i++) { for(my $j=0; $j<138; $j++) {
   $img2D[$i][$j] = sqrt($i*$j) / 128;
   $img1D[$k]      = $img2D[$i][$j];  $k++;  # For 1D test
}}

my $imgchar = pack("f*",@img1D);

PGPLOT::pgbegin(0,$dev,2,2);     # Open plot device

note "Plotting...";

my @tr=(0,1,0,0,0,1);

my @x=(10,20,30,40,50,60,70,80,90,100,110);
my @y=(30,35,40,45,50,55,60,65,70,75, 80);

nextplot('Points: scalars passed one by one','Image: packed char string');

PGPLOT::pggray($imgchar,138,128,1,138,1,128,1,0,\@tr);
for(my $i=0; $i<11; $i++){ PGPLOT::pgpt(1,$x[$i],$y[$i],17) }

nextplot('Points: 1D array passed by glob','Image: 1D array passed by glob');

PGPLOT::pggray(\@img1D,138,128,1,138,1,128,1,0,\@tr);
PGPLOT::pgpt(11,\@x,\@y,17);

nextplot('Points: 1D array passed by reference','Image: 1D array passed by reference');

PGPLOT::pggray(\@img1D,138,128,1,138,1,128,1,0,\@tr);
PGPLOT::pgpt(11,\@x,\@y,17);

nextplot('Line: 1D cross-section of 2D array','Image: 2D array passed by reference');

PGPLOT::pggray(\@img2D,138,128,1,138,1,128,1,0,\@tr);
PGPLOT::pgwindow(0,128,0,1);
PGPLOT::pgline(128, [0..127], $img2D[127]);

PGPLOT::pgend();

pass;
done_testing;

sub nextplot {
  note $_[0];
  note $_[1];
  note "--------------------------------------";
  PGPLOT::pgpage(); PGPLOT::pgwnad(0,128,0,128); PGPLOT::pgsci(3); PGPLOT::pgsch(1.3);
  PGPLOT::pgbox("BCST",0,0,"BCST",0,0);
  if ($^O ne 'freebsd') {
    # blows up for some reason
    PGPLOT::pgmtext('T',1.0,0.2,0,$_[0]);
    PGPLOT::pgmtext('T',2.4,0.2,0,$_[1]);
  }
  PGPLOT::pgsci(4);
}
