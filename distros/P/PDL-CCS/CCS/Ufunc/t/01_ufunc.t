# -*- Mode: CPerl -*-
# t/01_ufunc.t
use Test::More tests => 52;

##-- common subs
my $TEST_DIR;
BEGIN {
  use File::Basename;
  use Cwd;
  $TEST_DIR = Cwd::abs_path dirname( __FILE__ );
  eval qq{use lib ("$TEST_DIR/$_/blib/lib","$TEST_DIR/$_/blib/arch");} foreach (qw(../../.. ../.. ..));
  do "$TEST_DIR/common.plt" or  die("$0: failed to load $TEST_DIR/common.plt: $@");
}

##-- common modules
use PDL;
use PDL::CCS::Ufunc;
use PDL::VectorValued;

##-- basic data
my $a = pdl(double, [
		      [10,0,0,0,-2],
		      [3,9,0,0,0],
		      [0,7,8,7,0],
		      [3,0,8,7,5],
		      [0,8,0,9,9],
		      [0,4,0,0,2],
		     ]);

my $agood    = ($a!=0);
my $abad     = !$agood;
my $awhich   = $a->whichND;
my $awhich1  = $awhich->slice("(1)")->qsort->slice("*1,");
my $awhich1i = $awhich->slice("(1)")->qsorti;
my $avals    = $a->indexND($awhich)->index($awhich1i);

##-- i..(i+2): test_ufunc($pdl_ufunc_name, $ccs_ufunc_name, $missing_val)
sub test_ufunc {
  my ($pdl_ufunc_name, $ccs_ufunc_name, $missing_val) = @_;
  print "test_ufunc($pdl_ufunc_name, $ccs_ufunc_name, $missing_val)\n";

  my $ccs_ufunc = PDL->can("ccs_accum_${ccs_ufunc_name}")
    or die("no CCS Ufunc ccs_accum_${ccs_ufunc_name} defined!");
  my $pdl_ufunc = PDL->can("${pdl_ufunc_name}")
    or die("no PDL Ufunc ${pdl_ufunc_name} defined!");

  $missing_val = 0 if (!defined($missing_val));
  $missing_val = PDL->topdl($missing_val);
  if ($missing_val->isbad) { $a = $a->setbadif($abad); }
  else                     { $a->where($abad) .= $missing_val; $a->badflag(0); }

  my @ccs_ufunc_missing = $missing_val->isbad && $ccs_ufunc_name !~ /^n(?:bad|good)/ ? (0,0) : ($missing_val,$a->dim(0));

  my $dense_rc = $pdl_ufunc->($a);
  my ($which_rc,$nzvals_rc) = $ccs_ufunc->($awhich1, $avals, @ccs_ufunc_missing);
  my $decoded_rc = $dense_rc->zeroes;
  $decoded_rc   .= $missing_val;
  $decoded_rc->indexND($which_rc) .= $nzvals_rc;

  my $label = "${pdl_ufunc_name}:missing=$missing_val";

  ##-- exceptions
 SKIP: {
    ##-- RT bug #126294 (see also analogous tests in CCS/t/03_ufuncs.t)
    ## - maybe test ($Config{stdchar}=~/unsigned/) or ($Config{stdchar} eq 'unsigned char') instead
    skip("RT #126294 - PDL::borover() appears to be broken", 1)
      if ($label eq 'borover:missing=BAD' && pdl([10,0,-2])->setvaltobad(0)->borover->sclr != -2);

    ##-- actual test
    #isok("${label}:type", $nzvals_rc->type, $dense_rc->type);
    pdlok("${label}:vals", $decoded_rc, $dense_rc);
  }
}

my $BAD = pdl(0)->setvaltobad(0);

foreach $missing (0,1,31,$BAD) { ## *4
  foreach $pdl_ufunc_name (
			   qw(sumover prodover dsumover dprodover),  ## *13
			   qw(andover orover bandover borover),
			   qw(maximum minimum),
			   qw(nbadover ngoodover), #nnz
			   qw(average),
			  )
    {
      my $ccs_ufunc_name = $pdl_ufunc_name;
      $ccs_ufunc_name =~ s/over$//;
      test_ufunc($pdl_ufunc_name, $ccs_ufunc_name, $missing); ## *1
    }
}

print "\n";
# end of t/*.t

