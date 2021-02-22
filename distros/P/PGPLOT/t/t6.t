use strict; use warnings;
use Test::More;
use Config;
# Stop f77-linking causing spurious undefined symbols (alpha)
$ENV{'PERL_DL_NONLAZY'}=0 if $Config{'osname'} eq "dec_osf"; 
require PGPLOT;

my $dev = $ENV{PGPLOT_DEV} || '/NULL';

$ENV{PGPLOT_XW_WIDTH}=0.3;

note "Testing perl function passing to pgconx";

# Read in image (int*2 raw byte array)

my $img="";
open(my $fh,"test.img") || die "Data file test.img not found";
if($^O =~ /mswin32/i) {binmode($fh)}
read($fh, $img, 32768);
close($fh) or die "Can't close test.img: $!";

note length($img)," bytes read\n";

my @image = unpack("n*",$img);

print $#image+1," element image stored\n";

PGPLOT::pgbegin(0,$dev,1,1);

note "Plotting";

PGPLOT::pgsci(3);
PGPLOT::pgwnad(1,128,1,128);
PGPLOT::pgbox("BCNST",0,0,"BCNST",0,0);

PGPLOT::pglabel("X","Y","Dropped Galaxy");

PGPLOT::pgsci(5); PGPLOT::pgsls(1);
my @cont = (-1,1000,2000,3000,4000,5000);

PGPLOT::pgsci(5);

PGPLOT::pgconx(\@image, 128, 128, 1,128,1,128, \@cont, 6, "squashplot");
PGPLOT::pgwnad(0,1000,0,1000);

PGPLOT::pgend();

pass;
done_testing;

sub squashplot {
    my ($visible,$x,$y,$z) = @_;

    my $xworld = $x*$x/128;
    my $yworld = $y*$y/128;
    if ($visible) {
       PGPLOT::pgdraw($xworld,$yworld);
    }else{
       PGPLOT::pgmove($xworld,$yworld);
    }
}
