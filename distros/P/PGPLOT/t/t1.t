use strict; use warnings;
use Test::More;
use Config;
# Stop f77-linking causing spurious undefined symbols (alpha)
$ENV{'PERL_DL_NONLAZY'}=0 if $Config{'osname'} eq "dec_osf";
require PGPLOT;

diag <<EOF if $^O =~ /mswin32/i;
NOTE - Win32 only: If /XSERVE doesn't work properly then
try /PNG (assuming libpng.dll is in your path) with one test-file.
Then view the output '.png' file.
EOF

my $dev = $ENV{PGPLOT_DEV} || '/NULL';
diag "Using device '$dev' - set env var PGPLOT_DEV to change";

$ENV{PGPLOT_XW_WIDTH}=0.3;

PGPLOT::pgbegin(0,$dev,1,1);  # Open plot device

PGPLOT::pgscf(2);             # Set character font
PGPLOT::pgslw(4);             # Set line width
PGPLOT::pgsch(1.6);           # Set character height

# Define data limits and plot axes

PGPLOT::pgenv(0,10,-5,5,0,0);

PGPLOT::pglabel("X","Y","Data"); # Labels

PGPLOT::pgsci(5);                # Change colour

my ($i, @x, @y) = 0;
while(<DATA>){

   # Read data in 2 columns from file handle
   # and put in two perl arrays

   ($x[$i], $y[$i]) = split(' ');
   $i++;
}

# Plot points - note how perl arrays are passed

PGPLOT::pgpoint($i,\@x,\@y,17);
PGPLOT::pgend();    # Close plot

pass;
done_testing;

__DATA__
1 -4.5
2 -4
3  -3.2
4 -2.1
5 -1
6 0.3
7 1.2
8 2.4
9 2.9
