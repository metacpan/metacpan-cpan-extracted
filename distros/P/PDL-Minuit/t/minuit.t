use strict;
use warnings;
use PDL::LiteF;
use Test::More;
use Test::PDL;
use PDL::Minuit;
use File::Temp qw( tempfile tempdir );
require File::Spec;

my $tempd = tempdir( CLEANUP => 1 ) or die "Couldn't get tempdir\n";

my $logfile = File::Spec->catfile($tempd, 'minuit.log.' . $$);

my $x = sequence(10);
my $y = 3.0 + 4.0*$x;

mn_init(\&chi2,
        {Log => $logfile,
        Title => 'test title'});

my $pars = pdl(2.5,3.0);
my $steps = pdl(0.3,0.5);
my @names = ('intercept','slope');

mn_def_pars($pars,
            $steps,
            {Names => \@names});

my $arglis = pdl (3.0);

ok !mn_excm('set pri',$arglis);

ok !mn_excm('migrad');

ok !mn_excm('minos');

my $emat = mn_emat();
my $emat_test = pdl [[0.34545455, -0.054545455], [-0.054545455,  0.012121212]];
is_pdl $emat, $emat_test or diag $emat;

my @got = mn_pout(1);
is_pdl $got[0], pdl('3');
is_pdl $got[1], pdl('0.587753');
is_pdl $got[2], pdl('0');
is_pdl $got[3], pdl('0');
is_pdl $got[4], pdl('1');
is $got[5], 'intercept ';

my @got2 = mn_pout(2);
is_pdl $got2[0], pdl('4');
is_pdl $got2[1], pdl('0.110096');
is_pdl $got2[2], pdl('0');
is_pdl $got2[3], pdl('0');
is_pdl $got2[4], pdl('2');
is $got2[5], 'slope     ';

my @r1 = mn_err(1);
is_pdl $r1[0], pdl('0.587753');
is_pdl $r1[1], pdl('-0.587753');
is_pdl $r1[2], pdl('0.587753');
is_pdl $r1[3], pdl('0.842927');
my @r1a = mn_err(2);
is_pdl $r1a[0], pdl('0.110096');
is_pdl $r1a[1], pdl('-0.110096');
is_pdl $r1a[2], pdl('0.110096');
is_pdl $r1a[3], pdl('0.842927');
my @r2 = mn_stat();
is_pdl $r2[0], pdl('0');
is_pdl $r2[1], pdl('0');
is_pdl $r2[2], pdl('1');
is_pdl $r2[3], longlong('2');
is_pdl $r2[4], longlong('2');
is_pdl $r2[5], longlong('3');

done_testing;

sub chi2 {
    my ($npar,$grad,$fval,$xval,$iflag) = @_;
    if($iflag == 4){
        $fval = (($y - $xval->slice(0) - $xval->slice(1)*$x)**2)->sumover;
    }
    ($fval,$grad);
}
