#!/usr/bin/env perl
# lmer() with prior weights and offsets, against lme4::lmer() and lmerTest.
#
# PROVENANCE
#
# %EXPECT is frozen output of t/lmer.offset.weights.R.R under R 4.6.1 with
# lme4 2.0-6 and lmerTest 3.2-1 (re-run with `Rscript t/lmer.offset.weights.R.R`
# from the distribution root; it also writes the four CSV files read below).
# The models are lme4's own tests (its source tarball's tests/ directory):
#
#   pw_ML1 .. pw_REML3   tests/priorWeights.R, lmerMods: 1000 simulated rows
#                        in 100 groups, residual variance v = (rpois(1) + 1)^2,
#                        weights 1/v; (1|g), (x|g), (x+z|g) by ML and REML.
#                        That file checks them against nlme::lme(weights =
#                        varFixed(~v)) to 1e-2.
#   pw_sleep_ml          tests/priorWeights.R, sleepLmer: sleepstudy with
#                        simulated weights, by ML.
#   pw_small_reml        tests/priorWeights.R, the set.seed(2) model of 40 rows.
#                        The file records lme4.0's results in a comment, fixed
#                        effects c(-0.73065400610675, 2.02895402562926); lme4
#                        2.0-6, tightly converged, gives -0.73064587137 and
#                        2.0289124543, which this file pins.  lme4.0's sigma
#                        (1.736) and variance (2.357) are on weights rescaled to
#                        mean 1 and are not comparable.
#   pw5_ml               tests/priorWeights.R line 160 (fm_wt): sleepstudy with
#                        every weight 5, by ML.
#   off_none, off_3x     tests/offset.R: y ~ x + (1|block) on 2600 simulated
#                        rows, without and with offset(3*x); the slope moves by
#                        exactly 3.
#   sleep_off            tests/modFormula.R (fm2Off): Reaction ~ Days +
#                        (Days|Subject) + offset(0.5*Days).
#
# Each record holds lme4's default fit (pkg_*) and a tightly converged one:
# lme4's own criterion minimized by nlminb() at its tightest tolerances and then
# by Nelder-Mead, with lmerTest's Satterthwaite degrees of freedom on it.
#
# TOLERANCE
#
# As t/lmer.R.t, whose header explains them: theta is determined only to about
# sqrt(machine epsilon) of its size, so the criterion and log-likelihood are
# compared to 1e-12 relative, fixed effects to 1e-6 of their standard error,
# theta, standard errors, t, sigma and the variance components to 1e-5
# relative, the Satterthwaite df and log p-value to 1e-4, and against lme4's
# default fit standard errors to 1e-4 and theta to 1e-3.  The worst observed
# disagreement of each class is printed at the end.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Spec;
use Stats::LikeR qw(lmer);

my %EXPECT = (
  pw_ML1 => {
    names => ['Intercept', 'x'],
    coef => [-0.06532728065351909, 0.9078252995341192],
    se => [0.13733899954446616, 0.07799034822757236],
    df => [99.48760529883715, 975.8411713687054],
    t => [-0.47566445707483196, 11.640226260884557],
    p => [0.6353562325077319, 2.041303407879077e-29],
    logp => [-0.45356944131374843, -66.06137916756623],
    theta => [0.6978288696288274],
    sigma => 1.6175612940989865,
    crit => 5130.210056824551,
    loglik => -2565.1050284122757,
    vc_sdcor => [1.128780969416439, 1.6175612940989865],
    fitted => [-1.0516868772775694, -0.3162602030767686, -2.237018104725196],
    pkg_coef => [-0.06532728065310552, 0.9078252995315619],
    pkg_se => [0.13733899936702137, 0.07799034823284223],
    pkg_theta => [0.6978288681622643],
    pkg_crit => 5130.210056824552,
  },
  pw_REML1 => {
    names => ['Intercept', 'x'],
    coef => [-0.06532859971680907, 0.9078337599038682],
    se => [0.13807085647757747, 0.07805092482403414],
    df => [98.49695370793378, 974.104155275853],
    t => [-0.4731527085690118, 11.631300486837024],
    p => [0.6371511445612681, 2.253733581867158e-29],
    logp => [-0.45074837594899203, -65.96237948612506],
    theta => [0.7027297127318858],
    sigma => 1.6184175546523036,
    crit => 5135.601243690138,
    loglik => -2567.800621845069,
    vc_sdcor => [1.1373101032610544, 1.6184175546523036],
    fitted => [-1.0534898280718379, -0.31805630014974257, -2.243261403108027],
    pkg_coef => [-0.06532859971701513, 0.9078337599052434],
    pkg_se => [0.13807085657529744, 0.0780509248211711],
    pkg_theta => [0.7027297135367023],
    pkg_crit => 5135.601243690138,
  },
  pw_ML2 => {
    names => ['Intercept', 'x'],
    coef => [-0.07932365862962898, 1.0013405598039302],
    se => [0.1282896515571676, 0.14254998755501735],
    df => [101.82341456375102, 99.94639246200386],
    t => [-0.618316892023682, 7.024487177997553],
    p => [0.5377471243859739, 2.658545960393282e-10],
    logp => [-0.6203668583409732, -22.048071588035373],
    theta => [0.7618565869053573, -0.12277329199247963, 0.8522799880687433],
    sigma => 1.3947562063588177,
    crit => 4977.544244983841,
    loglik => -2488.7721224919205,
    vc_sdcor => [1.062604202941593, 1.2009931858902547, -0.14258100128576573, 1.3947562063588177],
    fitted => [-0.2581305912307559, -0.3792361560710188, -2.5779115358597453],
    pkg_coef => [-0.07932363693176701, 1.001340569694443],
    pkg_se => [0.12828960059630193, 0.14255003202050487],
    pkg_theta => [0.761856142609876, -0.12277265562096214, 0.8522804548694775],
    pkg_crit => 4977.544244983934,
  },
  pw_REML2 => {
    names => ['Intercept', 'x'],
    coef => [-0.07926763510324186, 1.0015012658431213],
    se => [0.1289248113156243, 0.14327211223948708],
    df => [100.81457260689302, 98.9580141810833],
    t => [-0.6148361536801836, 6.990203816979105],
    p => [0.5400482007580578, 3.248800339866383e-10],
    logp => [-0.6160968827442429, -21.847565127937614],
    theta => [0.7671605661140131, -0.12280773272697204, 0.8581696316743378],
    sigma => 1.3948168477085086,
    crit => 4981.874786358181,
    loglik => -2490.9373931790906,
    vc_sdcor => [1.0700484825134227, 1.209183817211507, -0.14166108758508292, 1.3948168477085086],
    fitted => [-0.2545451623220902, -0.38137839676807617, -2.5816877498293493],
    pkg_coef => [-0.07926773752032949, 1.0015012244746964],
    pkg_se => [0.12892489973785973, 0.14327196998042982],
    pkg_theta => [0.7671612512308221, -0.12281147838497455, 0.8581678023648251],
    pkg_crit => 4981.874786359592,
  },
  pw_ML3 => {
    names => ['Intercept', 'x', 'z'],
    coef => [-0.0742763197103095, 1.0245193651005593, 0.9350361805054542],
    se => [0.11814122313378224, 0.12785314416204557, 0.11808176123805658],
    df => [101.36756506812344, 100.2523227614711, 91.79436379351907],
    t => [-0.628707895009683, 8.013251233008766, 7.91854873014971],
    p => [0.530954468632177, 2.099551757338474e-12, 5.3825570653764406e-12],
    logp => [-0.6330790078720463, -26.889297242869066, -25.947857563707664],
    theta => [0.9565038781103354, -0.017869402436395024, -0.036881285538431334, 1.0448019299856595, -0.1983901641761372, 0.9190922537006039],
    sigma => 1.0608109192177284,
    crit => 4626.481892625143,
    loglik => -2313.2409463125714,
    vc_sdcor => [1.014669758173547, 1.1084993880254024, 0.9982052954075277, -0.017100647442115972, -0.03919441280661815, -0.21013175584277666, 1.0608109192177284],
    fitted => [1.8516288102626732, 1.5140261804889255, -3.4500065391462424],
    pkg_coef => [-0.07427640283385326, 1.0245192811773676, 0.93503638585757],
    pkg_se => [0.11814128458742112, 0.12785321903285005, 0.11808155451209972],
    pkg_theta => [0.956504499080585, -0.0178678679811874, -0.03688854092804619, 1.0448026696776156, -0.19838871264934704, 0.919089851385417],
    pkg_crit => 4626.481892628919,
  },
  pw_REML3 => {
    names => ['Intercept', 'x', 'z'],
    coef => [-0.07442006028405293, 1.0248850237750704, 0.9348848860433612],
    se => [0.11872014228634377, 0.12849480709020264, 0.11873252817480383],
    df => [100.35729959164209, 99.25311564004917, 90.93123503514846],
    t => [-0.6268528562285371, 7.97608126728115, 7.873873321950813],
    p => [0.5321791329464584, 2.6637771659731094e-12, 7.010403892004237e-12],
    logp => [-0.6307751302518533, -26.651276013155453, -25.683625799993425],
    theta => [0.9625020258151358, -0.017459386025274887, -0.03699173739547793, 1.0513837048821162, -0.19928039971613937, 0.9257944870070873],
    sigma => 1.0608780880872435,
    crit => 4633.638866313937,
    loglik => -2316.8194331569684,
    vc_sdcor => [1.0210973089268598, 1.115543715525061, 1.005417228717662, -0.016603813734859106, -0.03903227687195355, -0.20959604050812392, 1.0608780880872435],
    fitted => [1.8564350025350569, 1.5149590541474536, -3.4562210195539604],
    pkg_coef => [-0.07441997749447349, 1.0248849958224302, 0.934885014054934],
    pkg_se => [0.11872025387448179, 0.12849500279071394, 0.11873226403859145],
    pkg_theta => [0.9625033295078899, -0.0174604302008698, -0.036992294675671215, 1.0513858572554418, -0.1992787651981263, 0.9257919135559696],
    pkg_crit => 4633.638866315676,
  },
  pw_sleep_ml => {
    names => ['Intercept', 'Days'],
    coef => [249.89870680579708, 10.58132863060217],
    se => [6.512120140523694, 1.523396211228679],
    df => [17.603761426366713, 18.349557855271623],
    t => [38.37440056591164, 6.945880889429227],
    p => [2.0344350527434654e-18, 1.5496261054488066e-06],
    logp => [-40.73631350890002, -13.377496878422988],
    theta => [1.0391792758751635, 0.05035050772051505, 0.2560231187292466],
    sigma => 21.7300285402699,
    crit => 1790.4254260401615,
    loglik => -895.2127130200807,
    vc_sdcor => [22.58139532322431, 5.66995580489463, 0.19296763633313804, 21.7300285402699],
    fitted => [259.71015856536957, 280.1343712183155, 367.85126947183625],
    pkg_coef => [249.89870179503262, 10.581329630242244],
    pkg_se => [6.512177755006148, 1.5233933006491653],
    pkg_theta => [1.0391946788625916, 0.050355473017945185, 0.25602184841438624],
    pkg_crit => 1790.4254260486314,
  },
  pw_small_reml => {
    names => ['Intercept', 'x'],
    coef => [-0.7306458713740362, 2.028912454274346],
    se => [0.6659647636760981, 0.964224851609334],
    df => [27.52216870151213, 34.335455921372194],
    t => [-1.0971239189006052, 2.1041901698426475],
    p => [0.28209401042478527, 0.042757937204157596],
    logp => [-1.2655148932988984, -3.1522004352387616],
    theta => [0.8842336771559102],
    sigma => 1.2161399117803902,
    crit => 173.6664786363725,
    loglik => -86.83323931818624,
    vc_sdcor => [1.0753518661296386, 1.2161399117803902],
    fitted => [1.0829642041164387, -0.5461606060431632, -0.6105603444087748],
    pkg_coef => [-0.7306458670769871, 2.028912432314918],
    pkg_se => [0.6659647679180625, 0.9642248483574254],
    pkg_theta => [0.8842337115349883],
    pkg_crit => 173.66647863637252,
  },
  pw5_ml => {
    names => ['Intercept', 'Days'],
    coef => [251.4051048484865, 10.467285959595426],
    se => [6.632276765419254, 1.5022367966697296],
    df => [18.00000022400161, 17.999999598045196],
    t => [37.90630483928457, 6.967800271435292],
    p => [1.266756601581809e-18, 1.6524151206872692e-06],
    logp => [-41.21007189710026, -13.31327263072295],
    theta => [0.4155622619383308, 0.008123953751361181, 0.09957006101054318],
    sigma => 57.225039364340304,
    crit => 1751.939344463198,
    loglik => -875.969672231599,
    vc_sdcor => [23.780566797755274, 5.716834611495817, 0.08132010191109652, 57.225039364340304],
    fitted => [254.2207882248666, 273.76360814620193, 369.5258396483414],
    pkg_coef => [251.4051048484866, 10.467285959595209],
    pkg_se => [6.632349971225424, 1.5022469051301366],
    pkg_theta => [0.41556992756127703, 0.008122777337939143, 0.09957126155862361],
    pkg_crit => 1751.9393444705397,
  },
  off_none => {
    names => ['Intercept', 'x'],
    coef => [4.22431650416819, 2.934661234526965],
    se => [0.1883503419005397, 0.06825759926601153],
    df => [26.723348308259638, 2573.579347349683],
    t => [22.427973644979538, 42.99391226887557],
    p => [7.28641549743353e-19, 7.563343373576801e-305],
    logp => [-41.76310504310331, -700.265140025572],
    theta => [0.9364138778937767],
    sigma => 1.0029577772983287,
    crit => 7513.51651191584,
    loglik => -3756.75825595792,
    vc_sdcor => [0.9391835816036509, 1.0029577772983287],
    fitted => [6.266062390524784, 2.4393381469710422, 5.709234435164461],
    pkg_coef => [4.224316504113101, 2.9346612346406933],
    pkg_se => [0.18835036184975062, 0.06825759919421744],
    pkg_theta => [0.936413982648002],
    pkg_crit => 7513.5165119158455,
  },
  off_3x => {
    names => ['Intercept', 'x'],
    coef => [4.224316504147936, -0.06533876543171961],
    se => [0.18835034914085041, 0.06825759923995485],
    df => [26.72334288622578, 2573.5793475154433],
    t => [22.427972782726016, -0.9572379655783925],
    p => [7.286463551124626e-19, 0.33853706946123674],
    logp => [-41.76309844815512, -1.0831216816619236],
    theta => [0.9364139159129281],
    sigma => 1.0029577769109004,
    crit => 7513.51651191584,
    loglik => -3756.75825595792,
    vc_sdcor => [0.9391836193724611, 1.0029577769109004],
    fitted => [6.266062391389785, 2.439338145199094, 5.709234434193044],
    pkg_coef => [4.224316504007307, -0.06533876514883868],
    pkg_se => [0.18835039875924633, 0.06825759906138504],
    pkg_theta => [0.9364141764622878],
    pkg_crit => 7513.516511915842,
  },
  sleep_off => {
    names => ['Intercept', 'Days'],
    coef => [251.40510484848446, 9.96728595959525],
    se => [6.824556602236869, 1.5457889115048447],
    df => [16.999999503635337, 16.99999961654927],
    t => [36.83830606168348, 6.4480252674939775],
    p => [1.1708887489370086e-17, 6.011293751434694e-06],
    logp => [-38.98618350597409, -12.02187056612198],
    theta => [0.9667329688498761, 0.015169056058069803, 0.2309095981656026],
    sigma => 25.59181556156301,
    crit => 1743.6282719584906,
    loglik => -871.8141359792453,
    vc_sdcor => [24.74045183608827, 5.9221331786074645, 0.06555132638412144, 25.59181556156301],
    fitted => [253.66367029128284, 273.3299281630513, 369.48148514165246],
    pkg_coef => [251.40510484848517, 9.96728595959582],
    pkg_se => [6.824596694733307, 1.5457896438855732],
    pkg_theta => [0.9667417739177663, 0.01516905890578792, 0.23090995320197016],
    pkg_crit => 1743.628271959952,
  },
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

my (%worst, %worst_at);
sub close_to {
	my ($got, $want, $tol, $class, $name, $abs) = @_;
	my $r = !defined $got ? 9**9**9 : $got == $want ? 0
	      : defined $abs && abs($got - $want) <= $abs ? 0 : abs($got - $want) / (abs($want) || 1);
	($worst{$class}, $worst_at{$class}) = ($r, $name) if $r > ($worst{$class} // 0) && $r < 9**9**9;
	ok($r <= $tol, $name) or diag('got ' . ($got // 'undef') . ", want $want, relative $r > $tol");
}

# The data rows' names are 1 .. n, in file order: fitted values are checked at
# the first two rows and the last, as the generator records them.
sub check {
	my ($key, $fit, $nrow) = @_;
	my $e = $EXPECT{$key};
	ok($fit->{converged}, "$key: converged");
	is($fit->{nobs}, $nrow, "$key: nobs");
	for my $j (0 .. $#{ $e->{names} }) {
		my $nm = $e->{names}[$j];
		my $s = $fit->{summary}{$nm};
		{
			my $r = abs($fit->{coefficients}{$nm} - $e->{coef}[$j]) / $e->{se}[$j];
			($worst{'coef (SE units)'}, $worst_at{'coef (SE units)'}) = ($r, "$key: coef $nm")
				if $r > ($worst{'coef (SE units)'} // 0);
			ok($r <= 1e-6, "$key: coef $nm") or diag("got $fit->{coefficients}{$nm}, want $e->{coef}[$j]: $r SE");
		}
		close_to($s->{'Std. Error'}, $e->{se}[$j], 1e-5, 'theta-dependent', "$key: se $nm");
		close_to($s->{'t value'}, $e->{t}[$j], 1e-5, 'theta-dependent', "$key: t $nm");
		close_to($s->{df}, $e->{df}[$j], 1e-4, 'df', "$key: Satterthwaite df $nm");
		# against R's log p, not log() of its p: off_none's p is 7.6e-305, and
		# perl 5.10.1 and 5.18.4 read that literal 7% low
		close_to(log($s->{'Pr(>|t|)'}), $e->{logp}[$j], 1e-4, 'df', "$key: p $nm (log scale)");
		close_to($s->{'Std. Error'}, $e->{pkg_se}[$j], 1e-4, 'lme4 default', "$key: se $nm against lme4's default fit");
		ok(abs($fit->{coefficients}{$nm} - $e->{pkg_coef}[$j]) <= 1e-3 * $e->{se}[$j],
		   "$key: coef $nm within 1e-3 SE of lme4's default fit");
	}
	for my $j (0 .. $#{ $e->{theta} }) {
		close_to($fit->{theta}[$j], $e->{theta}[$j], 1e-5, 'theta-dependent', "$key: theta $j", 1e-6);
		close_to($fit->{theta}[$j], $e->{pkg_theta}[$j], 1e-3, 'lme4 default', "$key: theta $j against lme4's default fit", 1e-4);
	}
	my $crit = $fit->{reml} ? $fit->{REML} : $fit->{deviance};
	close_to($crit, $e->{crit}, 1e-12, 'criterion', "$key: criterion");
	close_to($fit->{loglik}, $e->{loglik}, 1e-12, 'criterion', "$key: logLik");
	ok($crit <= $e->{pkg_crit} + 1e-9 * abs($e->{pkg_crit}), "$key: at or below lme4's default optimum");
	close_to($fit->{sigma}, $e->{sigma}, 1e-5, 'theta-dependent', "$key: sigma");
	# the random-effect standard deviations (and correlations), in VarCorr's row order
	my @sd;
	for my $t (@{ $fit->{varcor} }) {
		my @n = @{ $t->{names} };
		push @sd, map { $t->{sd}{$_} } @n;
		for my $a (0 .. $#n) { push @sd, $t->{corr}[$a][$_] for $a + 1 .. $#n }
	}
	push @sd, $fit->{sigma};
	is(scalar @sd, scalar @{ $e->{vc_sdcor} }, "$key: VarCorr rows");
	close_to($sd[$_], $e->{vc_sdcor}[$_], 1e-5, 'theta-dependent', "$key: VarCorr row $_", 1e-7) for 0 .. $#sd;
	my @at = (1, 2, $nrow);
	close_to($fit->{fitted_values}{ $at[$_] }, $e->{fitted}[$_], 1e-5, 'theta-dependent', "$key: fitted value of row $at[$_]")
		for 0 .. 2;
}

my $SIM = read_csv('lmer.pw.sim.csv');
my $n = @{ $SIM->{y} };
check('pw_ML1',   lmer(formula => 'y ~ x + (1 | g)',         data => $SIM, weights => 'w', REML => 0), $n);
check('pw_REML1', lmer(formula => 'y ~ x + (1 | g)',         data => $SIM, weights => 'w'),            $n);
check('pw_ML2',   lmer(formula => 'y ~ x + (x | g)',         data => $SIM, weights => 'w', REML => 0), $n);
check('pw_REML2', lmer(formula => 'y ~ x + (x | g)',         data => $SIM, weights => 'w'),            $n);
check('pw_ML3',   lmer(formula => 'y ~ x + z + (x + z | g)', data => $SIM, weights => 'w', REML => 0), $n);
check('pw_REML3', lmer(formula => 'y ~ x + z + (x + z | g)', data => $SIM, weights => 'w'),            $n);
# weights as an array ref, one value per row
check('pw_REML1', lmer(formula => 'y ~ x + (1 | g)', data => $SIM, weights => [ @{ $SIM->{w} } ]), $n);

my $SL = read_csv('lmer.pw.sleep.csv');
check('pw_sleep_ml', lmer(formula => 'Reaction ~ Days + (Days | Subject)', data => $SL, weights => 'w', REML => 0), 180);
my $SM = read_csv('lmer.pw.small.csv');
check('pw_small_reml', lmer(formula => 'y ~ x + (1 | g)', data => $SM, weights => 'w'), 40);
check('pw5_ml', lmer(formula => 'Reaction ~ Days + (Days | Subject)', data => $SL, weights => [ (5) x 180 ], REML => 0), 180);

my $OFF = read_csv('lme4.offset.sim.csv');
check('off_none', lmer(formula => 'y ~ x + (1 | block)', data => $OFF), 2600);
check('off_3x',   lmer(formula => 'y ~ x + (1 | block) + offset(3 * x)', data => $OFF), 2600);
# the offset given by argument, as an expression and as values, and split
# between the two (they add)
check('off_3x',   lmer(formula => 'y ~ x + (1 | block)', data => $OFF, offset => 'I(3*x)'), 2600);
check('off_3x',   lmer(formula => 'y ~ x + (1 | block)', data => $OFF, offset => [ map { 3 * $_ } @{ $OFF->{x} } ]), 2600);
check('off_3x',   lmer(formula => 'y ~ x + (1 | block) + offset(x)', data => $OFF, offset => 'I(2*x)'), 2600);
check('sleep_off', lmer(formula => 'Reaction ~ Days + (Days | Subject) + offset(0.5 * Days)', data => $SL), 180);
{
	# tests/offset.R's check: the slope moves by exactly the offset's 3
	my $a = lmer(formula => 'y ~ x + (1 | block)', data => $OFF);
	my $b = lmer(formula => 'y ~ x + (1 | block) + offset(3 * x)', data => $OFF);
	cmp_ok(abs($a->{coefficients}{x} - 3 - $b->{coefficients}{x}), '<=', 1e-6 * $a->{summary}{x}{'Std. Error'},
		'offset.R: the slope with offset(3 * x) is the slope without, less 3');
}
{
	# tests/priorWeightsModComp.R: scaling every weight by 10 divides each
	# residual variance sigma^2 / w by 10 for the same sigma, so the fit has
	# sigma sqrt(10) times larger, theta (a random-effect sd relative to
	# sigma) sqrt(10) times smaller, and the same fixed effects, random-effect
	# sds and deviance (whose -sum(log w) offsets the change in sigma)
	my @w10 = map { 10 * $_ } @{ $SL->{w} };
	my $a = lmer(formula => 'Reaction ~ Days + (Days | Subject)', data => $SL, weights => 'w', REML => 0);
	my $b = lmer(formula => 'Reaction ~ Days + (Days | Subject)', data => $SL, weights => \@w10, REML => 0);
	close_to($b->{theta}[$_], $a->{theta}[$_] / sqrt(10), 1e-6, 'weights x 10', "weights x 10: theta $_ / sqrt(10)", 1e-8) for 0 .. 2;
	close_to($b->{coefficients}{$_}, $a->{coefficients}{$_}, 1e-9, 'weights x 10', "weights x 10: coef $_") for qw(Intercept Days);
	close_to($b->{sigma}, $a->{sigma} * sqrt(10), 1e-6, 'weights x 10', 'weights x 10: sigma * sqrt(10)');
	close_to($b->{varcor}[0]{sd}{$_}, $a->{varcor}[0]{sd}{$_}, 1e-6, 'weights x 10', "weights x 10: sd $_") for qw(Intercept Days);
	close_to($b->{deviance}, $a->{deviance}, 1e-12, 'weights x 10', 'weights x 10: the deviance is unchanged');
}
{
	# A zero weight drops the row, as glm() does; lme4 keeps it and its
	# criterion, which subtracts sum(log w), is infinite.  An undef weight
	# drops the row as a missing value does.
	my %d = map { $_ => [ @{ $SM->{$_} } ] } keys %$SM;
	my %e = map { $_ => [ @{ $SM->{$_} }[3 .. 39] ] } keys %$SM;
	$d{w}[$_] = 0 for 0 .. 1;
	$d{w}[2] = undef;
	my $a = lmer(formula => 'y ~ x + (1 | g)', data => \%d, weights => 'w');
	my $b = lmer(formula => 'y ~ x + (1 | g)', data => \%e, weights => 'w');
	is($a->{nobs}, 37, 'rows with a zero or missing weight are left out');
	close_to($a->{REML}, $b->{REML}, 1e-12, 'drop', 'and the fit is that of the other rows');
	$d{w}[0] = -1;
	eval { lmer(formula => 'y ~ x + (1 | g)', data => \%d, weights => 'w') };
	like($@, qr/^lmer: weights must be finite and non-negative/, 'a negative weight croaks');
	eval { lmer(formula => 'y ~ x + (1 | g)', data => $SM, weights => [1, 2]) };
	like($@, qr/'weights' has 2 elements but the data has 40 rows/, 'weights of the wrong length croak');
	eval { lmer(formula => 'y ~ x + (1 | g)', data => $SM, offset => {}) };
	like($@, qr/'offset' must be a column name or an array ref/, 'an offset that is a hash ref croaks');
}
SKIP: {
	skip 'Test::LeakTrace not installed', 2 unless eval { require Test::LeakTrace; 1 };
	Test::LeakTrace::no_leaks_ok(sub { lmer(formula => 'y ~ x + (1 | g) + offset(x)', data => $SM, weights => 'w') }, 'no leaks');
	Test::LeakTrace::no_leaks_ok(sub { eval { lmer(formula => 'y ~ x + (1 | g)', data => $SM, weights => [1]) } }, 'no leaks: croak');
}
diag(sprintf('worst relative disagreement, %s: %.3g (%s)', $_, $worst{$_}, $worst_at{$_})) for sort keys %worst;

done_testing();
