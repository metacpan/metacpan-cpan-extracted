use strict; use warnings;
use Test::More;
use Config;
# Stop f77-linking causing spurious undefined symbols (alpha)
$ENV{'PERL_DL_NONLAZY'}=0 if $Config{'osname'} eq "dec_osf";
require PGPLOT;

my $dev = $ENV{PGPLOT_DEV} || '/NULL';

$ENV{PGPLOT_XW_WIDTH}=0.3;

note "Testing scalars in array routines";

PGPLOT::pgbegin(0,$dev,1,1);     # Open plot device
PGPLOT::pgscf(2);
PGPLOT::pgslw(4);
PGPLOT::pgsch(1.6);
PGPLOT::pgenv(10.0,30.0,-2.0,6.0,0,0);
PGPLOT::pgsci(6);
PGPLOT::pglabel("X axis \\gP","Y axis \\gF","Top Label \\gW");
PGPLOT::pgsci(7);
PGPLOT::pgbbuf();

for(my $i=0; $i<10; $i++) {
   my $x = $i+15;
   my $y = $i-1;
   my $e = 0.9;
   my $x1 = $x - $e;
   my $x2 = $x + 2.0* $e;
   my $y1 = $y - 0.7* $e;
   my $y2 = $y + 0.3* $e;
   PGPLOT::pgsci(7);
   PGPLOT::pgpoint(1,$x,$y,$i+5);
   PGPLOT::pgsci(3);
   PGPLOT::pgerrb(3,1,$x,$y,4,3.0);
   PGPLOT::pgsci(2);
   PGPLOT::pgerrx(1,$x1,$x2,$y,1);
   PGPLOT::pgerry(1,$x,$y2,$y1,.1);
}

PGPLOT::pgebuf();
PGPLOT::pgiden();
PGPLOT::pgend();

pass;
done_testing;
