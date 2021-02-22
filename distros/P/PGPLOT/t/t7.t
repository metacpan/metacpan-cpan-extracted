use strict; use warnings;
use Test::More;
use Config;
# Stop f77-linking causing spurious undefined symbols (alpha)
$ENV{'PERL_DL_NONLAZY'}=0 if $Config{'osname'} eq "dec_osf";
require PGPLOT;

my $dev = $ENV{PGPLOT_DEV} || '/NULL';

$ENV{PGPLOT_XW_WIDTH}=0.3;

note "Testing pghi2d routine";

# Read in image (int*2)

my $img="";
open(my $fh,"test.img") || die "Data file test.img not found";
if($^O =~ /mswin32/i) {binmode($fh)}
read($fh, $img, 32768);
close($fh) or die "Can't close test.img: $!";

note length($img)," bytes read";

my @image = unpack("n*",$img);

note $#image+1," element image stored";

PGPLOT::pgbegin(0,$dev,1,1);

note "Plotting\n";

PGPLOT::pgenv(0,256,0,65000,0,0);

PGPLOT::pgsci(5);

my @xvals = (1..128);
my @work = (1..128);

PGPLOT::pghi2d(\@image, 128, 128, 1,128,1,128, \@xvals, 1, 200, 1, \@work);

PGPLOT::pgend();

pass;
done_testing;
