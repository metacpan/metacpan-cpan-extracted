#!/usr/bin/env perl
# zerotrunc() and hurdle() against countreg, pscl and Stata.
#
# PROVENANCE
#
# %PKG is frozen output of t/zerotrunc_hurdle.R.R under R 4.6.1 with
# countreg 0.3-0 (R-Forge) and pscl 1.5.9, and %EXACT of
# t/zerotrunc_hurdle.mpmath.py under mpmath 1.3.0; re-run the R script first
# (it rewrites t/CrabSatellites.csv, t/docvis.csv and t/bioChemists.csv) and
# then the python one.  The corpora:
#
#   crab_*    countreg's CrabSatellites, as countreg's own
#             inst/tinytest/test_zerotrunc.R (color as a number, positive
#             counts) and test_hurdle.R (every row) use it.
#   docvis_*  statsmodels 0.14.6's
#             sandbox/regression/tests/racd10data_with_transformed.csv,
#             filtered as its test_gmm_poisson.get_data() filters it -- the
#             corpus of discrete/tests/test_truncated_model.py.
#   bio_*     pscl's ?hurdle example, hurdle(art ~ ., data = bioChemists,
#             dist = "negbin"), and a variant with an offset and weights.
#
# %PKG is what countreg or pscl returns with its default control:
# optim(method = "BFGS"), stopped at its default reltol, with standard errors
# from optim()'s finite-difference Hessian (ndeps = 1e-3).  %EXACT answers the
# question they approximate, independently of them and of LikeR: each
# log-likelihood written out from its definition in mpmath at mp.dps = 60 and
# maximised by Newton on mpmath's numerical derivatives -- solving score = 0
# -- with the standard errors from the inverse Hessian there.  LikeR maximises
# by Newton on its analytic Hessian, so it is held to %EXACT tightly and to
# %PKG loosely.
#
# Two further sets of numbers are copied verbatim:
#
#   %COUNTREG  countreg inst/tinytest/test_zerotrunc.R's ref_list (zt_p,
#              zt_nb2, zt_g), which countreg checks itself against at 1e-6,
#              and from test_hurdle.R the parametrisation-invariant parts of
#              logit_p and nb2_nb2 (log-likelihood, width coefficients and
#              their standard errors, theta): there color is an ordered
#              factor with polynomial contrasts, which a treatment-coded
#              factor spans the same space as.
#   %STATA     statsmodels 0.14.6 discrete/tests/results/results_truncated_st.py,
#              Stata's `tpoisson docvis aget totchr if docvis > 0` and
#              `tnbreg docvis aget totchr if docvis > 0` (the latter reports
#              ln(alpha) = -ln(theta)), and results_truncated.py's
#              hurdle_poisson, pscl's hurdle(docvis ~ aget + totchr,
#              zero.dist = "poisson").
#
# TOLERANCE
#
# Against %EXACT: coefficients 1e-7 of their own standard error, standard
# errors 1e-6 relative, log-likelihoods 1e-10 relative -- observed 2.3e-13,
# 5.3e-13 and 2.0e-15.  Against Stata, whose Newton-Raphson stops on its own
# criterion: coefficients 1e-5 of their standard error, standard errors and
# log-likelihoods 1e-6 relative -- observed 4.3e-6 SE and 3.3e-7, which is
# where Stata stopped (the mpmath optimum agrees with this module's to 1e-13
# on the same data).  Against the packages' defaults: log-likelihoods 1e-8 relative,
# or 5e-7 for a negative-binomial zero hurdle, which countreg's own test calls
# poorly conditioned (observed 1.5e-7) -- BFGS stops short of the maximum,
# never beyond it, which is also checked; coefficients 5e-3 of
# their standard error; standard errors 5e-3 relative (optim()'s central
# differences at ndeps = 1e-3 carry an O(1e-6) truncation error per Hessian
# element, which the inverse amplifies).  The observed worst of each class is
# printed at the end.  None of these is loosened to make a failure go away.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Spec;
use Stats::LikeR qw(zerotrunc hurdle);

my %PKG = (
  crab_zt_poisson => {
    coef => [0.5626990696858772, 0.03423786411254256, 0.007165503612631893],
    se => [0.6454385455894488, 0.022227496221024427, 0.0666273068719676],
    ll => -267.5474337209408,
    theta => undef,
    sel => undef,
  },
  crab_zt_negbin => {
    coef => [0.42722392170113366, 0.03788960146487086, 0.006985057030496673],
    se => [0.9411305505568098, 0.03275077185750728, 0.09108130637537981],
    ll => -255.80216681492348,
    theta => 4.6054604333157325,
    sel => 0.3529368218846778,
  },
  crab_zt_geometric => {
    coef => [0.044092345011278136, 0.04460978347455665, 0.0076787063482905765],
    se => [1.5575677533802261, 0.0546318904214729, 0.1429377467161916],
    ll => -265.6237473009121,
    theta => undef,
    sel => undef,
  },
  crab_h_poisson_binomial => {
    count => [0.5626992683636723, 0.034237859727859817, 0.007165471983497899],
    zero => [-10.070838965526638, 0.45830973854084256, -0.509046697264782],
    ll => -362.10802225828155,
  },
  crab_h_poisson_poisson => {
    count => [0.5626992683636723, 0.034237859727859817, 0.007165471983497899],
    zero => [-6.789446855869085, 0.28485434280549854, -0.26603014411494263],
    ll => -362.1722878344189,
  },
  crab_h_poisson_geometric => {
    count => [0.5626992683636723, 0.034237859727859817, 0.007165471983497899],
    zero => [-10.070838965526638, 0.45830973854084256, -0.509046697264782],
    ll => -362.10802225828155,
  },
  crab_h_poisson_negbin => {
    count => [0.5626992683636723, 0.034237859727859817, 0.007165471983497899],
    zero => [-8.733417502711456, 0.3871944196032667, -0.4097186221608402],
    ll => -362.0767310165804,
  },
  crab_h_negbin_binomial => {
    count => [0.42856689938588094, 0.037845165273840256, 0.006928677805026969],
    zero => [-10.070838965526638, 0.45830973854084256, -0.509046697264782],
    ll => -350.3627542732586,
  },
  crab_h_negbin_poisson => {
    count => [0.42856689938588094, 0.037845165273840256, 0.006928677805026969],
    zero => [-6.789446855869085, 0.28485434280549854, -0.26603014411494263],
    ll => -350.42701984939595,
  },
  crab_h_negbin_geometric => {
    count => [0.42856689938588094, 0.037845165273840256, 0.006928677805026969],
    zero => [-10.070838965526638, 0.45830973854084256, -0.509046697264782],
    ll => -350.3627542732586,
  },
  crab_h_negbin_negbin => {
    count => [0.42856689938588094, 0.037845165273840256, 0.006928677805026969],
    zero => [-8.733417502711456, 0.3871944196032667, -0.4097186221608402],
    ll => -350.3314630315574,
  },
  crab_h_geometric_binomial => {
    count => [0.045162465449433746, 0.044571801916308974, 0.007660841814122349],
    zero => [-10.070838965526638, 0.45830973854084256, -0.509046697264782],
    ll => -360.1843360605103,
  },
  crab_h_geometric_poisson => {
    count => [0.045162465449433746, 0.044571801916308974, 0.007660841814122349],
    zero => [-6.789446855869085, 0.28485434280549854, -0.26603014411494263],
    ll => -360.24860163664766,
  },
  crab_h_geometric_geometric => {
    count => [0.045162465449433746, 0.044571801916308974, 0.007660841814122349],
    zero => [-10.070838965526638, 0.45830973854084256, -0.509046697264782],
    ll => -360.1843360605103,
  },
  crab_h_geometric_negbin => {
    count => [0.045162465449433746, 0.044571801916308974, 0.007660841814122349],
    zero => [-8.733417502711456, 0.3871944196032667, -0.4097186221608402],
    ll => -360.1530448188091,
  },
  docvis_zt_poisson => {
    coef => [1.5417559986737952, 0.012276323894180746, 0.20994371695405775],
    ll => -12557.823617402935,
  },
  docvis_zt_negbin => {
    coef => [1.4035693388664092, 0.018003885831175768, 0.23730019098601543],
    ll => -9335.541733694805,
  },
  bio_h_negbin => {
    count => [0.45854103840864735, -0.24467151159563108, -0.10341714112717565, -0.15325941235939297, -0.00293329311493356, 0.023738197275062604],
    zero => [0.563029596044564, -0.2511511286180422, -0.32623358360776467, -0.28524871578514754, 0.02221939709887045, 0.08012135468661018],
    ll => -1552.5965912130773,
    theta => 1.828460119179509,
  },
  bio_h_off_w => {
    count => [0.6192574105251881, -0.11639338250680163, -0.16395450913106205, -0.14121944160229002, -0.04995720171619449, 0.018240439789623697],
    zero => [1.086775144268824, -0.33634198608655624, -0.21676702732591155],
    ll => -3341.111521929612,
  },
);
my %EXACT = (
  crab_zt_poisson => {
    coef => [0.5626990524661156, 0.03423786476381818, 0.0071655049339795695],
    se => [0.6454912201845887, 0.022230882642283747, 0.06662739597855634],
    ll => -267.5474337209408,
  },
  crab_zt_negbin => {
    coef => [0.42856619713978816, 0.0378451882568431, 0.006928704283281956],
    se => [0.9408880555774434, 0.032742378330814094, 0.09107800907421149],
    ll => -255.80216573591767,
    theta => 4.606103357299661,
    sel => 0.3529192533355717,
  },
  crab_zt_geometric => {
    coef => [0.04413481566079666, 0.04460808070503207, 0.007679718242407764],
    se => [1.5576298147405325, 0.0546341334942781, 0.14293781636116212],
    ll => -265.6237473003016,
  },
  crab_h_poisson_binomial => {
    count => [0.5626990524661156, 0.03423786476381818, 0.0071655049339795695],
    zero => [-10.070838970070403, 0.4583097385160229, -0.5090466973823716],
    count_se => [0.6454912201845887, 0.022230882642283747, 0.06662739597855634],
    zero_se => [2.8068619992721096, 0.10401937757738602, 0.22368274078241523],
    ll => -362.10802225828144,
  },
  crab_h_negbin_binomial => {
    count => [0.42856619713978816, 0.0378451882568431, 0.006928704283281956],
    zero => [-10.070838970070403, 0.4583097385160229, -0.5090466973823716],
    count_se => [0.9408880555774434, 0.032742378330814094, 0.09107800907421149],
    zero_se => [2.8068619992721096, 0.10401937757738602, 0.22368274078241523],
    ll => -350.3627542732583,
    theta => 4.606103357299661,
  },
  crab_h_geometric_binomial => {
    count => [0.04413481566079666, 0.04460808070503207, 0.007679718242407764],
    zero => [-10.070838970070403, 0.4583097385160229, -0.5090466973823716],
    count_se => [1.5576298147405325, 0.0546341334942781, 0.14293781636116212],
    zero_se => [2.8068619992721096, 0.10401937757738602, 0.22368274078241523],
    ll => -360.18433583764227,
  },
  crab_h_poisson_poisson => {
    count => [0.5626990524661156, 0.03423786476381818, 0.0071655049339795695],
    zero => [-6.789453512522685, 0.28485454063337057, -0.2660294878419615],
    count_se => [0.6454912201845887, 0.022230882642283747, 0.06662739597855634],
    zero_se => [1.7524190350355975, 0.06263412926524102, 0.13531028959280628],
    ll => -362.172287834404,
  },
  crab_h_negbin_poisson => {
    count => [0.42856619713978816, 0.0378451882568431, 0.006928704283281956],
    zero => [-6.789453512522685, 0.28485454063337057, -0.2660294878419615],
    count_se => [0.9408880555774434, 0.032742378330814094, 0.09107800907421149],
    zero_se => [1.7524190350355975, 0.06263412926524102, 0.13531028959280628],
    ll => -350.4270198493809,
    theta => 4.606103357299661,
  },
  crab_h_geometric_poisson => {
    count => [0.04413481566079666, 0.04460808070503207, 0.007679718242407764],
    zero => [-6.789453512522685, 0.28485454063337057, -0.2660294878419615],
    count_se => [1.5576298147405325, 0.0546341334942781, 0.14293781636116212],
    zero_se => [1.7524190350355975, 0.06263412926524102, 0.13531028959280628],
    ll => -360.24860141376485,
  },
  crab_h_poisson_geometric => {
    count => [0.5626990524661156, 0.03423786476381818, 0.0071655049339795695],
    zero => [-10.070838970070403, 0.4583097385160229, -0.5090466973823716],
    count_se => [0.6454912201845887, 0.022230882642283747, 0.06662739597855634],
    zero_se => [2.8068619992721096, 0.10401937757738602, 0.22368274078241523],
    ll => -362.10802225828144,
  },
  crab_h_negbin_geometric => {
    count => [0.42856619713978816, 0.0378451882568431, 0.006928704283281956],
    zero => [-10.070838970070403, 0.4583097385160229, -0.5090466973823716],
    count_se => [0.9408880555774434, 0.032742378330814094, 0.09107800907421149],
    zero_se => [2.8068619992721096, 0.10401937757738602, 0.22368274078241523],
    ll => -350.3627542732583,
    theta => 4.606103357299661,
  },
  crab_h_geometric_geometric => {
    count => [0.04413481566079666, 0.04460808070503207, 0.007679718242407764],
    zero => [-10.070838970070403, 0.4583097385160229, -0.5090466973823716],
    count_se => [1.5576298147405325, 0.0546341334942781, 0.14293781636116212],
    zero_se => [2.8068619992721096, 0.10401937757738602, 0.22368274078241523],
    ll => -360.18433583764227,
  },
  crab_h_poisson_negbin => {
    count => [0.5626990524661156, 0.03423786476381818, 0.0071655049339795695],
    zero => [-8.719090610081915, 0.38644928278529206, -0.4088038263836884],
    count_se => [0.6454912201845887, 0.022230882642283747, 0.06662739597855634],
    zero_se => [5.51339773630028, 0.2777908956233254, 0.4154382029056461],
    ll => -362.0767265227191,
    theta_zero => 1.6806840277823523,
  },
  crab_h_negbin_negbin => {
    count => [0.42856619713978816, 0.0378451882568431, 0.006928704283281956],
    zero => [-8.719090610081915, 0.38644928278529206, -0.4088038263836884],
    count_se => [0.9408880555774434, 0.032742378330814094, 0.09107800907421149],
    zero_se => [5.51339773630028, 0.2777908956233254, 0.4154382029056461],
    ll => -350.331458537696,
    theta => 4.606103357299661,
    theta_zero => 1.6806840277823523,
  },
  crab_h_geometric_negbin => {
    count => [0.04413481566079666, 0.04460808070503207, 0.007679718242407764],
    zero => [-8.719090610081915, 0.38644928278529206, -0.4088038263836884],
    count_se => [1.5576298147405325, 0.0546341334942781, 0.14293781636116212],
    zero_se => [5.51339773630028, 0.2777908956233254, 0.4154382029056461],
    ll => -360.15304010207996,
    theta_zero => 1.6806840277823523,
  },
  docvis_zt_poisson => {
    coef => [1.5417559978079363, 0.012276324231768871, 0.20994371600858358],
    se => [0.015472724442458924, 0.005043281691664397, 0.004493744459972479],
    ll => -12557.823617402935,
  },
  docvis_zt_negbin => {
    coef => [1.4035620953274035, 0.01798958828831053, 0.23731210117089915],
    se => [0.03662965459318824, 0.012375560004057942, 0.011668784737159446],
    ll => -9335.54173237229,
    theta => 1.6995994341569254,
    sel => 0.04237842572141168,
  },
  docvis_h_poisson_poisson => {
    count => [1.5417559978079363, 0.012276324231768871, 0.20994371600858358],
    zero => [0.2167350277367518, 0.01893227900902299, 0.3867460560259199],
    count_se => [0.015472724442458924, 0.005043281691664397, 0.004493744459972479],
    zero_se => [0.04917622488386739, 0.018749595513883752, 0.023717238141164738],
    ll => -13612.9091771461,
  },
  bio_h_negbin => {
    count => [0.4585418501538418, -0.2446712380244157, -0.10341721934738048, -0.15325935297676502, -0.0029335562333372435, 0.023738215625551343],
    zero => [0.5630295960393193, -0.2511511286201353, -0.3262335836094497, -0.28524871578798033, 0.022219397080547272, 0.08012135455963823],
    count_se => [0.17983110413736003, 0.0972181487904503, 0.10942973500169867, 0.07222907915077949, 0.04806731516396169, 0.004286803084103029],
    zero_se => [0.27449909061477656, 0.15910521424967647, 0.18081824051638218, 0.11113041683530199, 0.07955713350527664, 0.013018064081797554],
    ll => -1552.5965912130407,
    theta => 1.8284618700237685,
    sel => 0.2249916791724343,
  },
  bio_h_off_w => {
    count => [0.6192573834037707, -0.1163933761572123, -0.1639545046698657, -0.14121943855120417, -0.04995719595985973, 0.018240439759725786],
    zero => [1.0867751426412768, -0.33634199419385247, -0.21676703259107383],
    count_se => [0.0774284051014675, 0.04625737897399646, 0.05142525848593742, 0.033203862298610665, 0.02236292349492603, 0.001644053211536291],
    zero_se => [0.08910499814253055, 0.108673267928959, 0.06759322184216722],
    ll => -3341.111521929612,
  },
);

my %COUNTREG = (
	# test_zerotrunc.R ref_list
	zt_poisson => { coef => [0.56269906967054, 0.0342378636202522, 0.00716550359326728],
	                se   => [0.645438550516392, 0.0222274963924805, 0.0666273073717945],
	                ll   => -267.547433720941 },
	zt_negbin  => { coef => [0.427223921701066, 0.0378896014648731, 0.00698505703049874],
	                se   => [0.941130550556333, 0.0327507718574901, 0.0910813063753843],
	                theta => 4.60546043331554, sel => 0.352936821886573,
	                ll   => -255.802166814923 },
	zt_geometric => { coef => [0.0440923450112795, 0.0446097834745566, 0.00767870634829046],
	                  se   => [1.55756775337772, 0.0546318904213941, 0.142937746716148],
	                  ll   => -265.623747300912 },
	# test_hurdle.R ref_list, the parts a change of contrasts leaves alone
	h_logit_poisson => { count_width => 0.0397109265472577, count_width_se => 0.0222775187986676,
	                     zero_width => 0.467955985251572, zero_width_se => 0.105528725732993,
	                     ll => -355.646193700518 },
	h_negbin_negbin => { count_width => 0.0420235024635511, count_width_se => 0.0316794941991245,
	                     zero_width => 0.29276682441464, zero_width_se => 0.0636257145756324,
	                     theta => 5.44999491584071, theta_zero => 8608.19058947861,
	                     ll => -345.907624112724 },
);
my %STATA = (
	# rows aget totchr _cons (/lnalpha)
	tpoisson => { coef => [0.01227632422998, 0.20994371600381, 1.5417559978312],
	              se   => [0.00504328169164, 0.00449374445996, 0.01547272444235],
	              ll   => -12557.82361740294 },
	tnbreg   => { coef => [0.01798960271895, 0.23731215078822, 1.4035619564653],
	              se   => [0.01237555909354, 0.01166878414467, 0.0366296524502],
	              lnalpha => -0.53039277265033, lnalpha_se => 0.04237842368148,
	              ll   => -9335.541732372312 },
);
# results_truncated.py hurdle_poisson: params_table columns 0 and 1, zero
# rows then count rows, each (Intercept) aget totchr
my %PSCL_DOCVIS = (
	zero  => [0.216740121452838, 0.0189277243223132, 0.386748883124962],
	zero_se => [0.0491761691242311, 0.0187496185721929, 0.0237172557549267],
	count => [1.54175599063303, 0.0122763123129474, 0.209943725275436],
	count_se => [0.0154727114729348, 0.00504327547820388, 0.00449373404468738],
	loglik => -13612.9091771797,
);

sub read_csv {
	my $f = File::Spec->catfile('t', shift);
	my %d;
	open my $fh, '<', $f or die "cannot open $f: $!";
	my $h = <$fh>; $h =~ s/[\r\n"]+//g;
	my @c = split /,/, $h;
	while (my $l = <$fh>) {
		$l =~ s/[\r\n]+//; $l =~ s/"//g;
		my @v = split /,/, $l;
		push @{ $d{ $c[$_] } }, $v[$_] for 0 .. $#c;
	}
	return \%d;
}

my %worst;
sub track { my ($c, $r) = @_; $worst{$c} = $r if !defined $worst{$c} || $r > $worst{$c}; $r }
sub rel { my ($g, $w) = @_; return 9**9**9 unless defined $g; $g == $w ? 0 : abs($g - $w) / abs($w) }
# coefficient disagreement in units of its standard error
sub coef_ok {
	my ($got, $want, $se, $tol, $class, $name) = @_;
	my $r = track($class, defined $got ? abs($got - $want) / $se : 9**9**9);
	ok($r <= $tol, $name) or diag("got $got, want $want: $r SE > $tol");
}
sub rel_ok {
	my ($got, $want, $tol, $class, $name) = @_;
	my $r = track($class, rel($got, $want));
	ok($r <= $tol, $name) or diag("got " . ($got // 'undef') . ", want $want: relative $r > $tol");
}

my %CRAB = %{ read_csv('CrabSatellites.csv') };
my @CN = qw(Intercept width colorn);
my %pos;
for my $i (0 .. $#{ $CRAB{satellites} }) {
	next unless $CRAB{satellites}[$i] > 0;
	push @{ $pos{$_} }, $CRAB{$_}[$i] for keys %CRAB;
}
# --------------------------------------------------- zerotrunc, CrabSatellites
for my $d (qw(poisson negbin geometric)) {
	my $e = $EXACT{"crab_zt_$d"};
	my $k = $PKG{"crab_zt_$d"};
	my $z = zerotrunc(formula => 'satellites ~ width + colorn', data => \%pos, dist => $d);
	ok($z->{converged}, "crab zerotrunc $d: converged");
	is($z->{dist}, $d, "crab zerotrunc $d: dist recorded");
	for my $j (0 .. 2) {
		coef_ok($z->{coefficients}{ $CN[$j] }, $e->{coef}[$j], $e->{se}[$j], 1e-7, 'exact coef',
		        "crab zerotrunc $d: $CN[$j] at the MLE");
		rel_ok($z->{summary}{ $CN[$j] }{'Std. Error'}, $e->{se}[$j], 1e-6, 'exact se',
		       "crab zerotrunc $d: se $CN[$j] from the Hessian at the MLE");
		coef_ok($z->{coefficients}{ $CN[$j] }, $k->{coef}[$j], $e->{se}[$j], 5e-3, 'pkg coef',
		        "crab zerotrunc $d: $CN[$j] near countreg's BFGS stop");
		rel_ok($z->{summary}{ $CN[$j] }{'Std. Error'}, $k->{se}[$j], 5e-3, 'pkg se',
		       "crab zerotrunc $d: se $CN[$j] near countreg's optimHess");
		my $c = $COUNTREG{"zt_$d"};
		coef_ok($z->{coefficients}{ $CN[$j] }, $c->{coef}[$j], $e->{se}[$j], 5e-3, 'pkg coef',
		        "crab zerotrunc $d: $CN[$j] against countreg's tinytest");
		rel_ok($z->{summary}{ $CN[$j] }{'Std. Error'}, $c->{se}[$j], 5e-3, 'pkg se',
		       "crab zerotrunc $d: se $CN[$j] against countreg's tinytest");
	}
	rel_ok($z->{loglik}, $e->{ll}, 1e-10, 'exact ll', "crab zerotrunc $d: loglik");
	rel_ok($z->{loglik}, $k->{ll}, 1e-8, 'pkg ll', "crab zerotrunc $d: loglik against countreg");
	rel_ok($z->{loglik}, $COUNTREG{"zt_$d"}{ll}, 1e-8, 'pkg ll', "crab zerotrunc $d: loglik against countreg's tinytest");
	if ($d eq 'negbin') {
		rel_ok($z->{theta}, $e->{theta}, 1e-7, 'exact se', 'crab zerotrunc negbin: theta');
		rel_ok($z->{'SE.logtheta'}, $e->{sel}, 1e-6, 'exact se', 'crab zerotrunc negbin: SE.logtheta');
		rel_ok($z->{theta}, $COUNTREG{zt_negbin}{theta}, 5e-3, 'pkg se', 'crab zerotrunc negbin: theta, tinytest');
		rel_ok($z->{'SE.logtheta'}, $COUNTREG{zt_negbin}{sel}, 5e-3, 'pkg se', 'crab zerotrunc negbin: SE.logtheta, tinytest');
		is($z->{'df.residual'}, 111 - 4, 'crab zerotrunc negbin: df.residual counts theta');
	} elsif ($d eq 'geometric') {
		is($z->{theta}, 1, 'geometric: theta is 1');
	}
	is($z->{nobs}, 111, "crab zerotrunc $d: 111 positive counts");
	# fitted values are the truncated means, mu / (1 - f(0))
	my $mu = exp($z->{coefficients}{Intercept} + $z->{coefficients}{width} * $pos{width}[0]
	             + $z->{coefficients}{colorn} * $pos{colorn}[0]);
	my $p0 = $d eq 'poisson' ? exp(-$mu)
	       : ($z->{theta} / ($z->{theta} + $mu)) ** $z->{theta};
	rel_ok($z->{'fitted.values'}{1}, $mu / (1 - $p0), 1e-12, 'identity', "crab zerotrunc $d: fitted = mu/(1 - f(0))");
}
{
	# a supplied theta: Inf is Poisson, 1 is the geometric (countreg's rule)
	my $a = zerotrunc(formula => 'satellites ~ width + colorn', data => \%pos, theta => 9**9**9);
	is($a->{dist}, 'poisson', 'theta => Inf fits the Poisson');
	my $b = zerotrunc(formula => 'satellites ~ width + colorn', data => \%pos, theta => 1);
	is($b->{dist}, 'geometric', 'theta => 1 fits the geometric');
	rel_ok($b->{loglik}, $EXACT{crab_zt_geometric}{ll}, 1e-10, 'exact ll', 'theta => 1 reproduces the geometric fit');
	my $nb = zerotrunc(formula => 'satellites ~ width + colorn', data => \%pos, dist => 'negbin');
	my $f = zerotrunc(formula => 'satellites ~ width + colorn', data => \%pos, theta => $nb->{theta});
	rel_ok($f->{loglik}, $nb->{loglik}, 1e-12, 'identity', 'theta fixed at the MLE gives the same likelihood');
	rel_ok($f->{coefficients}{width}, $nb->{coefficients}{width}, 1e-8, 'identity', 'and the same coefficients');
	ok(!exists $f->{'SE.logtheta'}, 'a fixed theta has no standard error');
}

# --------------------------------------------------- hurdle, CrabSatellites
for my $cd (qw(poisson negbin geometric)) {
	for my $zd (qw(binomial poisson geometric negbin)) {
		my $e = $EXACT{"crab_h_${cd}_$zd"};
		my $h = hurdle(formula => 'satellites ~ width + colorn | width + colorn', data => \%CRAB,
		               dist => $cd, 'zero.dist' => $zd);
		my $tag = "crab hurdle $cd/$zd";
		ok($h->{converged}, "$tag: converged");
		for my $j (0 .. 2) {
			coef_ok($h->{coefficients}{count}{ $CN[$j] }, $e->{count}[$j], $e->{count_se}[$j], 1e-7, 'exact coef',
			        "$tag: count $CN[$j]");
			coef_ok($h->{coefficients}{zero}{ $CN[$j] }, $e->{zero}[$j], $e->{zero_se}[$j], 1e-7, 'exact coef',
			        "$tag: zero $CN[$j]");
			rel_ok($h->{summary}{count}{ $CN[$j] }{'Std. Error'}, $e->{count_se}[$j], 1e-6, 'exact se', "$tag: count se $CN[$j]");
			rel_ok($h->{summary}{zero}{ $CN[$j] }{'Std. Error'}, $e->{zero_se}[$j], 1e-6, 'exact se', "$tag: zero se $CN[$j]");
		}
		rel_ok($h->{loglik}, $e->{ll}, 1e-10, 'exact ll', "$tag: loglik");
		# a negative-binomial zero hurdle is the case countreg itself calls
		# poorly conditioned, and its BFGS stops furthest short there
		rel_ok($h->{loglik}, $PKG{"crab_h_${cd}_$zd"}{ll}, ($zd eq 'negbin' ? 5e-7 : 1e-8), 'pkg ll',
		       "$tag: loglik against countreg");
		cmp_ok($h->{loglik}, '>=', $PKG{"crab_h_${cd}_$zd"}{ll} - 1e-12 * abs($h->{loglik}),
		       "$tag: at or above countreg's maximum");
		rel_ok($h->{theta}, $e->{theta}, 1e-6, 'exact se', "$tag: theta") if $cd eq 'negbin';
		rel_ok($h->{'theta.zero'}, $e->{theta_zero}, 1e-6, 'exact se', "$tag: zero theta") if $zd eq 'negbin';
	}
}
{
	# countreg's test_hurdle.R, color as the ordered factor it is
	for my $pair (['poisson', 'binomial', 'h_logit_poisson'], ['negbin', 'negbin', 'h_negbin_negbin']) {
		my ($cd, $zd, $k) = @$pair;
		my $c = $COUNTREG{$k};
		my $h = hurdle(formula => 'satellites ~ width + color | width + color', data => \%CRAB,
		               dist => $cd, 'zero.dist' => $zd);
		rel_ok($h->{loglik}, $c->{ll}, ($zd eq 'negbin' ? 5e-7 : 1e-8), 'pkg ll', "countreg tinytest $k: loglik");
		cmp_ok($h->{loglik}, '>=', $c->{ll} - 1e-12 * abs($c->{ll}), "countreg tinytest $k: at or above countreg's maximum");
		coef_ok($h->{coefficients}{count}{width}, $c->{count_width}, $c->{count_width_se}, 5e-3, 'pkg coef', "countreg tinytest $k: count width");
		coef_ok($h->{coefficients}{zero}{width}, $c->{zero_width}, $c->{zero_width_se}, 5e-3, 'pkg coef', "countreg tinytest $k: zero width");
		rel_ok($h->{summary}{count}{width}{'Std. Error'}, $c->{count_width_se}, 5e-3, 'pkg se', "countreg tinytest $k: count width se");
		# the negbin zero hurdle is poorly conditioned -- countreg's own test
		# loosens theta there by 100 and the SE of log(theta) by 1000 -- so its
		# zero width se is held at the looser bound too
		rel_ok($h->{summary}{zero}{width}{'Std. Error'}, $c->{zero_width_se}, ($zd eq 'negbin' ? 5e-2 : 5e-3), 'pkg se',
		       "countreg tinytest $k: zero width se");
		if ($cd eq 'negbin') {
			rel_ok($h->{theta}, $c->{theta}, 5e-3, 'pkg se', "countreg tinytest $k: theta");
			# With color a factor the zero hurdle's likelihood keeps rising as
			# its theta grows: there is no finite maximum, the negative
			# binomial is tending to the Poisson, and countreg's 8608 is
			# where BFGS gave up.  So theta runs off toward infinity here,
			# with a log-likelihood above countreg's (checked above).
			cmp_ok($h->{'theta.zero'}, '>', 1e6, "countreg tinytest $k: the zero theta runs past countreg's 8608 toward infinity");
		}
	}
}

# --------------------------------------------------- docvis and Stata
{
	my $dv = read_csv('docvis.csv');
	my %dp;
	for my $i (0 .. $#{ $dv->{docvis} }) {
		next unless $dv->{docvis}[$i] > 0;
		push @{ $dp{$_} }, $dv->{$_}[$i] for keys %$dv;
	}
	my @N = qw(aget totchr Intercept);
	for my $pair (['poisson', 'tpoisson'], ['negbin', 'tnbreg']) {
		my ($d, $s) = @$pair;
		my $z = zerotrunc(formula => 'docvis ~ aget + totchr', data => \%dp, dist => $d);
		my $e = $EXACT{"docvis_zt_$d"};
		my @RN = qw(Intercept aget totchr);
		for my $j (0 .. 2) {
			coef_ok($z->{coefficients}{ $RN[$j] }, $e->{coef}[$j], $e->{se}[$j], 1e-7, 'exact coef', "docvis zerotrunc $d: $RN[$j]");
			rel_ok($z->{summary}{ $RN[$j] }{'Std. Error'}, $e->{se}[$j], 1e-6, 'exact se', "docvis zerotrunc $d: se $RN[$j]");
			coef_ok($z->{coefficients}{ $N[$j] }, $STATA{$s}{coef}[$j], $STATA{$s}{se}[$j], 1e-5, 'Stata coef', "Stata $s: $N[$j]");
			rel_ok($z->{summary}{ $N[$j] }{'Std. Error'}, $STATA{$s}{se}[$j], 1e-6, 'Stata', "Stata $s: se $N[$j]");
		}
		rel_ok($z->{loglik}, $e->{ll}, 1e-10, 'exact ll', "docvis zerotrunc $d: loglik");
		rel_ok($z->{loglik}, $STATA{$s}{ll}, 1e-6, 'Stata', "Stata $s: loglik");
		is($z->{nobs}, 3237, "docvis zerotrunc $d: Stata's N");
		if ($d eq 'negbin') {
			rel_ok(-log($z->{theta}), $STATA{tnbreg}{lnalpha}, 1e-6, 'Stata', 'Stata tnbreg: ln(alpha) = -ln(theta)');
			rel_ok($z->{'SE.logtheta'}, $STATA{tnbreg}{lnalpha_se}, 1e-6, 'Stata', 'Stata tnbreg: se of ln(alpha)');
		}
	}
	my $h = hurdle(formula => 'docvis ~ aget + totchr', data => $dv, 'zero.dist' => 'poisson');
	my $e = $EXACT{docvis_h_poisson_poisson};
	my @RN = qw(Intercept aget totchr);
	for my $j (0 .. 2) {
		coef_ok($h->{coefficients}{count}{ $RN[$j] }, $e->{count}[$j], $e->{count_se}[$j], 1e-7, 'exact coef', "docvis hurdle: count $RN[$j]");
		coef_ok($h->{coefficients}{zero}{ $RN[$j] }, $e->{zero}[$j], $e->{zero_se}[$j], 1e-7, 'exact coef', "docvis hurdle: zero $RN[$j]");
		coef_ok($h->{coefficients}{count}{ $RN[$j] }, $PSCL_DOCVIS{count}[$j], $e->{count_se}[$j], 5e-3, 'pkg coef',
		        "statsmodels' pscl hurdle_poisson: count $RN[$j]");
		coef_ok($h->{coefficients}{zero}{ $RN[$j] }, $PSCL_DOCVIS{zero}[$j], $e->{zero_se}[$j], 5e-3, 'pkg coef',
		        "statsmodels' pscl hurdle_poisson: zero $RN[$j]");
		rel_ok($h->{summary}{count}{ $RN[$j] }{'Std. Error'}, $PSCL_DOCVIS{count_se}[$j], 5e-3, 'pkg se',
		       "statsmodels' pscl hurdle_poisson: count se $RN[$j]");
		rel_ok($h->{summary}{zero}{ $RN[$j] }{'Std. Error'}, $PSCL_DOCVIS{zero_se}[$j], 5e-3, 'pkg se',
		       "statsmodels' pscl hurdle_poisson: zero se $RN[$j]");
	}
	rel_ok($h->{loglik}, $PSCL_DOCVIS{loglik}, 1e-8, 'pkg ll', "statsmodels' pscl hurdle_poisson: loglik");
	is($h->{'df.residual'}, 3623, 'docvis hurdle: df.residual, as pscl');
}

# --------------------------------------------------- bioChemists
{
	my $bc = read_csv('bioChemists.csv');
	my $h = hurdle(formula => 'art ~ fem + mar + kid5 + phd + ment', data => $bc, dist => 'negbin');
	my $e = $EXACT{bio_h_negbin};
	my $k = $PKG{bio_h_negbin};
	my @BN = qw(Intercept femWomen marSingle kid5 phd ment);
	for my $j (0 .. $#BN) {
		my $nm = $BN[$j];
		coef_ok($h->{coefficients}{count}{$nm}, $e->{count}[$j], $e->{count_se}[$j], 1e-7, 'exact coef', "bioChemists: count $nm");
		coef_ok($h->{coefficients}{zero}{$nm}, $e->{zero}[$j], $e->{zero_se}[$j], 1e-7, 'exact coef', "bioChemists: zero $nm");
		rel_ok($h->{summary}{count}{$nm}{'Std. Error'}, $e->{count_se}[$j], 1e-6, 'exact se', "bioChemists: count se $nm");
		rel_ok($h->{summary}{zero}{$nm}{'Std. Error'}, $e->{zero_se}[$j], 1e-6, 'exact se', "bioChemists: zero se $nm");
		coef_ok($h->{coefficients}{count}{$nm}, $k->{count}[$j], $e->{count_se}[$j], 5e-3, 'pkg coef', "bioChemists: count $nm, pscl");
	}
	rel_ok($h->{loglik}, $e->{ll}, 1e-10, 'exact ll', 'bioChemists: loglik');
	rel_ok($h->{loglik}, $k->{ll}, 1e-8, 'pkg ll', 'bioChemists: loglik, pscl');
	rel_ok($h->{theta}, $e->{theta}, 1e-6, 'exact se', 'bioChemists: theta');
	rel_ok($h->{'SE.logtheta'}, $e->{sel}, 1e-6, 'exact se', 'bioChemists: SE.logtheta');
	rel_ok($h->{theta}, $k->{theta}, 5e-3, 'pkg se', 'bioChemists: theta, pscl');
	# the hurdle mean on row 1
	my %r = map { ($_ => $bc->{$_}[0]) } keys %$bc;
	my $ec = $h->{coefficients}{count}{Intercept} + ($r{fem} eq 'Women' ? $h->{coefficients}{count}{femWomen} : 0)
	       + ($r{mar} eq 'Single' ? $h->{coefficients}{count}{marSingle} : 0)
	       + $h->{coefficients}{count}{kid5} * $r{kid5} + $h->{coefficients}{count}{phd} * $r{phd}
	       + $h->{coefficients}{count}{ment} * $r{ment};
	my $ez = $h->{coefficients}{zero}{Intercept} + ($r{fem} eq 'Women' ? $h->{coefficients}{zero}{femWomen} : 0)
	       + ($r{mar} eq 'Single' ? $h->{coefficients}{zero}{marSingle} : 0)
	       + $h->{coefficients}{zero}{kid5} * $r{kid5} + $h->{coefficients}{zero}{phd} * $r{phd}
	       + $h->{coefficients}{zero}{ment} * $r{ment};
	my ($mu, $th) = (exp($ec), $h->{theta});
	my $want = (1 / (1 + exp(-$ez))) * $mu / (1 - ($th / ($th + $mu)) ** $th);
	rel_ok($h->{'fitted.values'}{1}, $want, 1e-12, 'identity', 'bioChemists: fitted = P(y > 0) mu/(1 - f(0))');

	my $o = hurdle(formula => 'art ~ fem + mar + kid5 + phd + ment | fem + kid5', data => $bc,
	               dist => 'poisson', offset => 'log(expo)', weights => 'wt');
	my $eo = $EXACT{bio_h_off_w};
	my @cn = @BN;
	my @zn = qw(Intercept femWomen kid5);
	for my $j (0 .. $#cn) {
		coef_ok($o->{coefficients}{count}{ $cn[$j] }, $eo->{count}[$j], $eo->{count_se}[$j], 1e-7, 'exact coef',
		        "bioChemists offset/weights: count $cn[$j]");
	}
	for my $j (0 .. $#zn) {
		coef_ok($o->{coefficients}{zero}{ $zn[$j] }, $eo->{zero}[$j], $eo->{zero_se}[$j], 1e-7, 'exact coef',
		        "bioChemists offset/weights: zero $zn[$j]");
	}
	rel_ok($o->{loglik}, $eo->{ll}, 1e-10, 'exact ll', 'bioChemists offset/weights: loglik');
	rel_ok($o->{loglik}, $PKG{bio_h_off_w}{ll}, 1e-8, 'pkg ll', 'bioChemists offset/weights: loglik, pscl');
	is_deeply($o->{terms}{zero}, [qw(Intercept femWomen kid5)], 'the zero half has its own regressors after |');
}

# --------------------------------------------------- errors
{
	my %d = (y => [1, 2, 3, 1, 4, 2], x => [1, 2, 3, 4, 5, 6]);
	eval { zerotrunc(formula => 'y ~ x', data => { y => [0, 1, 2], x => [1, 2, 3] }) };
	like($@, qr/no zeros allowed/, 'zerotrunc: a zero croaks, as countreg');
	eval { zerotrunc(formula => 'y ~ x', data => { y => [-1, 1, 2], x => [1, 2, 3] }) };
	like($@, qr/negative counts/, 'zerotrunc: a negative count croaks');
	eval { zerotrunc(formula => 'y ~ x', data => { y => [1.5, 1, 2], x => [1, 2, 3] }) };
	like($@, qr/non-integer values/, 'zerotrunc: a fraction croaks');
	eval { zerotrunc(formula => 'y ~ x', data => \%d, dist => 'binomial') };
	like($@, qr/dist must be 'poisson', 'negbin' or 'geometric'/, 'zerotrunc: unknown dist');
	eval { zerotrunc(formula => 'y ~ x', data => \%d, theta => -1) };
	like($@, qr/theta must be positive/, 'zerotrunc: bad theta');
	eval { zerotrunc(formula => 'y ~ x', data => \%d, colour => 1) };
	like($@, qr/unknown argument 'colour'/, 'zerotrunc: unknown argument');
	eval { hurdle(formula => 'y ~ x', data => \%d) };
	like($@, qr/no zero counts/, 'hurdle: no zeros croaks');
	eval { hurdle(formula => 'y ~ x', data => { y => [0, 0, 0], x => [1, 2, 3] }) };
	like($@, qr/no positive counts/, 'hurdle: no positive counts croaks');
	eval { hurdle(formula => 'y ~ x', data => \%d, 'zero.dist' => 'gamma') };
	like($@, qr/zero.dist must be/, 'hurdle: unknown zero.dist');
	eval { hurdle(formula => 'y ~ x', data => \%d, link => 'probit') };
	like($@, qr/only link = 'logit'/, 'hurdle: only the logit link');
	eval { hurdle(formula => 'y ~ x', data => { y => [0, 1, -2], x => [1, 2, 3] }) };
	like($@, qr/negative counts/, 'hurdle: a negative count croaks');
}

SKIP: {
	skip 'Test::LeakTrace not installed', 3 unless eval { require Test::LeakTrace; 1 };
	Test::LeakTrace::no_leaks_ok(sub {
		zerotrunc(formula => 'satellites ~ width + colorn', data => \%pos, dist => 'negbin');
	}, 'no leaks: zerotrunc');
	Test::LeakTrace::no_leaks_ok(sub {
		hurdle(formula => 'satellites ~ width + colorn | width', data => \%CRAB, dist => 'negbin', 'zero.dist' => 'negbin');
	}, 'no leaks: hurdle');
	Test::LeakTrace::no_leaks_ok(sub {
		eval { zerotrunc(formula => 'y ~ x', data => { y => [0, 1, 2], x => [1, 2, 3] }) };
	}, 'no leaks: croak');
}

diag(sprintf('worst disagreement, %s: %.3g', $_, $worst{$_})) for sort keys %worst;
done_testing();
