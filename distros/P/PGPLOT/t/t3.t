use strict; use warnings;
use Test::More;
use Config;
# Stop f77-linking causing spurious undefined symbols (alpha)
$ENV{'PERL_DL_NONLAZY'}=0 if $Config{'osname'} eq "dec_osf"; 
require PGPLOT;

my $dev = $ENV{PGPLOT_DEV} || '/NULL';

$ENV{PGPLOT_XW_WIDTH}=0.3;

note "Testing histogram routines";

my $i=0; my @data=();
while(<DATA>){
  $i++;
  chop;
  $data[$i-1] = $_;
}

PGPLOT::pgbegin(0,$dev,1,1);

PGPLOT::pgscf(2);
PGPLOT::pgslw(4);
PGPLOT::pgsch(1.6);

PGPLOT::pgsci(6);

PGPLOT::pgsci(7);

PGPLOT::pghist($i,\@data,0,10,10,2);

PGPLOT::pglabel("Data Value","Number of data items","Test histogram");

PGPLOT::pgend();

pass;
done_testing;

__DATA__
1
1
2
3
4
7
3
5
7
3
5
6
2
2
2
2
1
6
7
