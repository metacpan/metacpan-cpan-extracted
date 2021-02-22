use strict; use warnings;
use Test::More;
use Config;
# Stop f77-linking causing spurious undefined symbols (alpha)
$ENV{'PERL_DL_NONLAZY'}=0 if $Config{'osname'} eq "dec_osf"; 
require PGPLOT;

my $dev = $ENV{PGPLOT_DEV} || '/NULL';

$ENV{PGPLOT_XW_WIDTH}=0.3;

PGPLOT::pgbegin(0,$dev,2,2);

PGPLOT::pgsci(3); PGPLOT::pgscf(2); PGPLOT::pgsch(1.4);

my $pi=3.141592654;

# Anonymous subs!

PGPLOT::pgfunx(sub{ sqrt($_[0]) },  500, 0, 10, 0);
PGPLOT::pgfuny(sub{ sin(4*$_[0]) }, 360, 0, 2*$pi, 0);

# Pass by name and pass by reference

PGPLOT::pgfunt("funt_x",  "funt_y",  360,0, 2*$pi, 0);
PGPLOT::pgfunt(\&funt_x2, \&funt_y2, 360,0, 2*$pi, 0);

PGPLOT::pgend();

pass;
done_testing;

sub funt_x {
   my($t)=$_[0];
   return cos($t);;
}

sub funt_y {
   my($t)=$_[0];
   return sin($t);
}

sub funt_x2 {
   my($t)=$_[0];
   return cos(4*$t)*cos($t);;
}

sub funt_y2 {
   my($t)=$_[0];
   return cos(4*$t)*sin($t);
}
