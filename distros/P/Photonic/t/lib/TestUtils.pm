package # hide from CPAN
  TestUtils;

use PDL;
use Photonic::Geometry::FromB;
use Photonic::LE::NR2::Haydock;
use Machine::Epsilon;
use File::Temp qw(tempdir);
use File::Spec::Functions;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
    machine_epsilon
    make_fn make_store make_default_store
    agree Cagree
);

sub make_fn { catfile tempdir(CLEANUP => 1), "remStore.dat" }

sub make_store {
    my ($B, $d0, $nh, $ah_args) = @_;
    my $g=Photonic::Geometry::FromB->new(B=>$B, Direction0=>pdl($d0)); #long
    my $a=Photonic::LE::NR2::Haydock->new(geometry=>$g, nh=>$nh, %$ah_args);
    $a->run;
    ($a, $g);
}

sub make_default_store {
    my ($fn) = @_;
    make_store(
        zeroes(1,11)->yvals<5, #2D flat system
        [1,0], 10, #trans
        {keepStates=>1, storeAllFN=>$fn},
    );
}

sub agree {
    my $a=shift;
    my $b=shift//0;
    return (($a-$b)*($a-$b))->sum<=1e-7;
}

sub Cagree {
    my $a=shift;
    my $b=shift//0;
    my $prec=shift//1e-7;
    my $ret = (($a-$b)->abs2)->sum<=$prec;
    Test::More::diag("different a=$a, b=$b") if !$ret;
    $ret;
}

1;
