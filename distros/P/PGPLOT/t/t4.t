use strict; use warnings;
use Test::More;
use Config;
# Stop f77-linking causing spurious undefined symbols (alpha)
$ENV{'PERL_DL_NONLAZY'}=0 if $Config{'osname'} eq "dec_osf"; 
require PGPLOT;

my $dev = $ENV{PGPLOT_DEV} || '/NULL';

$ENV{PGPLOT_XW_WIDTH}=0.3;

note "Testing greyscale, contour and vector routines";

# Read in image (int*2)

my $img="";
open my $fh, "test.img" or die "Data file test.img not found: $!";
binmode $fh if $^O =~ /mswin32/i;
read($fh, $img, 32768);
close $fh or die "Can't close test.img: $!";

note length($img)," bytes read\n";

my @image = unpack("n*",$img);

note $#image+1," element image stored\n";

PGPLOT::pgbegin(0,$dev,1,1);

note "Plotting...\n";

PGPLOT::pgsci(3);
PGPLOT::pgwnad(12000,13000,13000,12000);

my @tr=(12000,8,0,12000,0,8);
PGPLOT::pggray(\@image,128,128,1,128,1,128,5000,0,\@tr);
PGPLOT::pglabel("\\ga","\\gd","Galaxy");
PGPLOT::pgtbox("ZYHBCNST",0,0,"ZYDBCNST",0,0);

PGPLOT::pgwedg('R', 2, 5, 5000, 0, 'Counts');

PGPLOT::pgsci(4); PGPLOT::pgsls(1);
my @cont = (-1,1000,2000,3000,4000,5000);
PGPLOT::pgcons(\@image, 128, 128, 1,128,1,128, \@cont, 6, \@tr);
PGPLOT::pgwnad(0,1000,0,1000);

@tr=(0,100,0,0,0,100);
PGPLOT::pgsah(1,30,0.5);
PGPLOT::pgsci(2);
PGPLOT::pgvect([(30) x 100], [(50) x 100], 10, 10, 1,9,1,9, 1, 1, \@tr, -10000);

PGPLOT::pgend();

pass;
done_testing;
