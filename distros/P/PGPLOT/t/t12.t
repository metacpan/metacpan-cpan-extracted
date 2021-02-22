use strict; use warnings;
use Test::More;
use Config;
# Stop f77-linking causing spurious undefined symbols (alpha)
$ENV{'PERL_DL_NONLAZY'}=0 if $Config{'osname'} eq "dec_osf";
require PGPLOT;

my $dev = $ENV{PGPLOT_DEV} || '/NULL';

$ENV{PGPLOT_XW_WIDTH}=0.3;

note "Testing some new PGPLOT 5.2.0 routines";

PGPLOT::pgqinf("VERSION", my $val, my $len);
$val =~ s/\.//g; $val =~ s/v//;
plan skip_all => "PGPLOT version must be > 5.2.0 for this test $val\n" if $val<520;

# Read in image (int*2)

my $img="";
open(my $fh,"test.img") || die "Data file test.img not found";
if($^O =~ /mswin32/i) {binmode($fh)}
read($fh, $img, 32768);
close($fh) or die "can't close test.img: $!";

note length($img)," bytes read";

my @image = unpack("n*",$img);

note $#image+1," element image stored";

PGPLOT::pgbegin(0,$dev,1,1);

note "Plotting";

PGPLOT::pgsci(3);
PGPLOT::pgwnad(12000,13000,13000,12000);

my @tr=(12000,8,0,12000,0,8);
PGPLOT::pglabel("\\ga","\\gd","Galaxy");
PGPLOT::pgtbox("ZYHBCNST",0,0,"ZYDBCNST",0,0);

PGPLOT::pgsci(4); PGPLOT::pgconf(\@image, 128, 128, 1,128,1,128, 1000,2000, \@tr);
PGPLOT::pgsci(2); PGPLOT::pgconf(\@image, 128, 128, 1,128,1,128, 2000,3000, \@tr);

my @cont = (-1,1000,2000,3000,4000,5000);
PGPLOT::pgsci(7);
PGPLOT::pgcons(\@image, 128, 128, 1,128,1,128, \@cont, 6, \@tr);

PGPLOT::pgsci(1);
PGPLOT::pgaxis('LN2',12500,12800,12900,12100,1,4,0,0, 1,2,0.5, -2,30);

PGPLOT::pgtick(12500,12800,12900,12100, 0.35, 3,5, 6,90,'pgperl!');

PGPLOT::pgqndt(my $ndrivers);

note "Testing pgqdt() - $ndrivers drivers found";
for my $n (1..$ndrivers) {
  PGPLOT::pgqdt($n,my $type,my $tlen,my $descr,my $dlen,my $inter);
  note "$n:  $type $tlen $descr $dlen $inter";
}

PGPLOT::pgend();

pass;
done_testing;
