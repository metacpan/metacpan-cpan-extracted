#!/usr/bin/env perl
# svyglm() against survey::svyglm().
#
# PROVENANCE
#
# %EXPECT is frozen output of t/svyglm.R.R under R 4.6.1 with survey 4.5
# (re-run with `Rscript t/svyglm.R.R`; it also writes t/apistrat.csv,
# t/apiclus1.csv, t/apiclus2.csv and t/survey_fpc.csv from survey's own api
# and fpc data).  The designs and models are survey's own:
#
#   strat_*, clus2_api00   survey man/svyglm.Rd: the stratified sample
#                          (strata stype, fpc) and the two-stage cluster
#                          sample, whose variance without an fpc is the
#                          ultimate-cluster one, by district; the
#                          quasibinomial model of sch.wide; the regression
#                          estimator api.stu ~ enroll.
#   fpc_domain, strat_domain  survey tests/domain.R: domain means as
#                          regression coefficients, on the fpc data with
#                          nest = TRUE and on apistrat.  @DOMAIN below is
#                          that test's printed output.
#   clus1_*                survey man/svydesign.Rd's one-stage cluster
#                          sample of districts, with its fpc.
#   strat_nofpc, strat_nest, strat_missing, strat_factor
#                          the same designs without the fpc, with PSUs
#                          nested in strata, with a covariate (acs.k3) whose
#                          missing values drop rows while their PSUs stay in
#                          the design's counts, and with a factor.
#
# TOLERANCE
#
# 1e-9 relative on coefficients, standard errors, t values, p-values,
# confidence limits, dispersion and deviance; degrees of freedom exactly.
# svyglm() is glm() at the same weights followed by a sum over PSUs, and both
# are done here the way survey does them, so they agree to rounding: the
# observed worst is printed at the end (4.8e-12 on this build).  @DOMAIN is
# printed to four or five figures and is held to half a unit in the last.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Spec;
use Stats::LikeR qw(svyglm);

my %EXPECT = (
  strat_api00 => {
    names => ['Intercept', 'ell', 'meals', 'mobility'],
    coef => [820.8873159056232, -0.4805866121719494, -3.1415353099845613, 0.22571321022963628],
    se => [10.077735949885389, 0.3919734032225283, 0.28394650641650143, 0.39321836202252897],
    t => [81.4555292962363, -1.2260694430308432, -11.063828006309263, 0.5740149291825398],
    p => [5.594749814545701e-152, 0.2216587151554869, 2.254134651846002e-22, 0.5666226131622016],
    df => 194,
    dispersion => 5171.965987282496,
    deviance => 1029221.2314692166,
    ci => [801.0113244897284, 840.7633073215179, -1.253663028983467, 0.2924898046395684, -3.7015537855799514, -2.581516834389171, -0.5498185984025248, 1.0012450188617978],
  },
  clus2_api00 => {
    names => ['Intercept', 'ell', 'meals', 'mobility'],
    coef => [811.4907225021707, -2.0591641823839004, -1.7771813339210774, 0.32525174881911806],
    se => [30.87953774810857, 1.4075396960609976, 1.1052685813833987, 0.5304816127158586],
    t => [26.279238022333285, -1.4629528304931472, -1.6079180787865024, 0.6131253959094948],
    p => [4.378844386143725e-25, 0.152156948042435, 0.11658948551878788, 0.5436478782611252],
    df => 36,
    dispersion => 8363.10107388547,
    deviance => 1045387.6342356837,
    ci => [748.8641172421824, 874.117327762159, -4.9137869961070555, 0.7954586313392547, -4.018769913296921, 0.46440724545476564, -0.750614827560349, 1.401118325198585],
  },
  strat_schwide => {
    names => ['Intercept', 'ell', 'meals', 'mobility'],
    coef => [0.8358365250542884, -0.0024896357495189174, -0.003152365111503177, 0.060896778706658],
    se => [0.4556260955945678, 0.013252498611026018, 0.009199483717659164, 0.031935421453053614],
    t => [1.8344790457262248, -0.18786161180560712, -0.34266761138475127, 1.9068725551713408],
    p => [0.06811454053711453, 0.8511814844078092, 0.7322195210480569, 0.058014753523037504],
    df => 194,
    dispersion => 1.108676711324315,
    deviance => 178.24511017232683,
    ci => [-0.06278003028404089, 1.7344530803926181, -0.028627108485635346, 0.023647836986597524, -0.021296208164360328, 0.014991477941353979, -0.0020884161645265617, 0.12388197357784259],
  },
  strat_apistu => {
    names => ['Intercept', 'enroll'],
    coef => [13.343827005611043, 0.8145409161374642],
    se => [11.463985760378055, 0.024593841705605784],
    t => [1.1639779815262956, 33.119710449783135],
    p => [0.24584786539885445, 3.146268671359476e-82],
    df => 196,
    dispersion => 7331.63307153099,
    deviance => 1458994.9812346671,
    ci => [-9.264771876977168, 35.952425888199244, 0.766038387110808, 0.8630434451641203],
  },
  fpc_domain => {
    names => ['gt4FALSE', 'gt4TRUE'],
    coef => [3.314285721097674, 6.194999957084656],
    se => [0.31170424677690906, 0.7555128710556582],
    t => [10.632789753005044, 8.19972788607631],
    p => [0.00012728178154187625, 0.00043901156585678325],
    df => 5,
    dispersion => 2.5573787768271177,
    deviance => 17.901651437789823,
    ci => [2.5130244462422517, 4.115546995953094, 4.252892294159539, 8.13710762000977],
  },
  strat_domain => {
    names => ['comp.impNo', 'comp.impYes'],
    coef => [744.9551685257393, 516.6729189323796],
    se => [51.87079427068278, 22.300333925805614],
    t => [14.361745930441357, 23.168842253724883],
    p => [1.984698775632313e-32, 4.9527163657927275e-58],
    df => 196,
    dispersion => 183742.88665909276,
    deviance => 36564834.44515945,
    ci => [642.6586369441745, 847.2517001073039, 472.69351114046987, 560.6523267242893],
  },
  clus1_api00 => {
    names => ['Intercept', 'ell', 'meals', 'mobility'],
    coef => [819.2790511391253, -0.5167217796834802, -3.123204264899352, -0.16891968218716674],
    se => [21.3899712651521, 0.32400394496541335, 0.2780830437608844, 0.44491841915120217],
    t => [38.302017379231835, -1.5948008896578065, -11.231192749691369, -0.37966439445106603],
    p => [4.646620299650624e-13, 0.13906346730593247, 2.2905074124112613e-07, 0.7114222316707224],
    df => 11,
    dispersion => 3157.849946920045,
    deviance => 574728.6903394482,
    ci => [772.2000418097389, 866.3580604685117, -1.229849654363503, 0.1964060949965425, -3.735260917490172, -2.511147612308532, -1.148178520190394, 0.8103391558160606],
  },
  clus1_poisson => {
    names => ['Intercept', 'ell', 'meals'],
    coef => [6.296180352946512, -0.0006054622934336159, -0.002690616635174246],
    se => [0.15216289484538637, 0.00487613022427501, 0.001711319999241553],
    t => [41.377895441225, -0.12416860616630412, -1.5722463574122383],
    p => [2.572044889470069e-14, 0.9032374548761061, 0.14187494556647154],
    df => 12,
    dispersion => 197.9522444148092,
    deviance => 28781.128736572224,
    ci => [5.964645885458078, 6.627714820434945, -0.01122963738521215, 0.010018712798344919, -0.006419262605187854, 0.0010380293348393622],
  },
  strat_nofpc => {
    names => ['Intercept', 'ell', 'meals', 'mobility'],
    coef => [820.8873159056232, -0.4805866121719494, -3.1415353099845613, 0.22571321022963628],
    se => [10.256489937131112, 0.3977074728300146, 0.2883000540559524, 0.40269076251276187],
    t => [80.03589151233908, -1.2083922103655278, -10.896755882587735, 0.5605125104464821],
    p => [1.5364971173435857e-150, 0.2283673062428749, 7.051730906436754e-22, 0.5757766434844006],
    df => 194,
    dispersion => 5171.965987282496,
    deviance => 1029221.2314692166,
    ci => [800.658773804364, 841.1158580068823, -1.264972148299878, 0.3037989239559796, -3.71014014624079, -2.5729304737283325, -0.5685007063450263, 1.019927126804299],
  },
  strat_nest => {
    names => ['Intercept', 'ell', 'meals'],
    coef => [823.857925625165, -0.5057255519026618, -3.1106289944093177],
    se => [8.595478228982207, 0.4099297273548257, 0.27046088407583585],
    t => [95.84782878598695, -1.2336884059762698, -11.501215804415965],
    p => [3.1545253903833845e-141, 0.2191627336411261, 1.3642555690048618e-22],
    df => 157,
    dispersion => 5178.26839678682,
    deviance => 1030475.410960577,
    ci => [806.8802301758186, 840.8356210745113, -1.3154143069968534, 0.30396320319153014, -3.6448404016720217, -2.5764175871466133],
  },
  strat_missing => {
    names => ['Intercept', 'acs.k3', 'ell'],
    coef => [681.0640856220909, 4.844802651073272, -3.862410557051025],
    se => [132.09446168573584, 6.95197773600194, 0.33056955363458607],
    t => [5.155886756572743, 0.6968955936069356, -11.684108577405652],
    p => [1.3942279638825135e-06, 0.48758802847978766, 5.1851675217595835e-20],
    df => 94,
    dispersion => 10301.572396484195,
    deviance => 988950.9500624829,
    ci => [418.78743540431253, 943.3407358398692, -8.958512111093299, 18.648117413239834, -4.518764154959875, -3.2060569591421753],
  },
  strat_factor => {
    names => ['Intercept', 'stypeH', 'stypeM', 'ell'],
    coef => [775.7306583868246, -94.30409173057109, -59.75026975434801, -4.029461351902181],
    se => [11.849649018573977, 13.762882733480284, 15.85848199630205, 0.3094400140647052],
    t => [65.46444178818204, -6.852059525375609, -3.767716845047391, -13.021785059315578],
    p => [3.2630185984235765e-134, 9.410892391306364e-11, 0.00021845626681868947, 2.888619765945113e-28],
    df => 194,
    dispersion => 7720.161618089294,
    deviance => 1536312.1619997695,
    ci => [752.3599803549974, 799.1013364186518, -121.44817850054949, -67.16000496059267, -91.02743891169283, -28.473100597003175, -4.639759844923757, -3.4191628588806036],
  },
);

# tests/domain.Rout.save: summary(svyglm(x ~ I(x > 4) + 0, design = dfpc))
my @DOMAIN = ([3.3143, 0.3117, 10.63], [6.1950, 0.7555, 8.20]);

sub read_csv {
	my $f = File::Spec->catfile('t', shift);
	my %d;
	open my $fh, '<', $f or die "cannot open $f: $!";
	my $h = <$fh>; $h =~ s/[\r\n"]+//g;
	my @c = split /,/, $h;
	while (my $l = <$fh>) {
		$l =~ s/[\r\n]+//; $l =~ s/"//g;
		my @v = split /,/, $l;
		push @{ $d{ $c[$_] } }, ($v[$_] eq 'NA' ? undef : $v[$_]) for 0 .. $#c;
	}
	return \%d;
}
my %D = (strat => read_csv('apistrat.csv'), clus1 => read_csv('apiclus1.csv'),
         clus2 => read_csv('apiclus2.csv'), fpc => read_csv('survey_fpc.csv'));

my ($worst, $worst_at) = (0, '');
sub close_to {
	my ($got, $want, $name) = @_;
	my $r = !defined $got ? 9**9**9 : $got == $want ? 0 : abs($got - $want) / (abs($want) || 1);
	($worst, $worst_at) = ($r, $name) if $r > $worst && $r < 9**9**9;
	ok($r <= 1e-9, $name) or diag('got ' . ($got // 'undef') . ", want $want, relative $r");
}
sub check {
	my ($key, $fit) = @_;
	my $e = $EXPECT{$key};
	is_deeply([ sort @{ $fit->{terms} } ], [ sort @{ $e->{names} } ], "$key: terms");
	for my $j (0 .. $#{ $e->{names} }) {
		my $nm = $e->{names}[$j];
		my $s = $fit->{summary}{$nm};
		close_to($fit->{coefficients}{$nm}, $e->{coef}[$j], "$key: coef $nm");
		close_to($s->{'Std. Error'}, $e->{se}[$j], "$key: se $nm");
		close_to($s->{'t value'}, $e->{t}[$j], "$key: t $nm");
		close_to($s->{'Pr(>|t|)'}, $e->{p}[$j], "$key: p $nm");
		close_to($fit->{'conf.int'}{$nm}[0], $e->{ci}[2 * $j], "$key: lower limit $nm");
		close_to($fit->{'conf.int'}{$nm}[1], $e->{ci}[2 * $j + 1], "$key: upper limit $nm");
	}
	is($fit->{'df.residual'}, $e->{df}, "$key: df.residual = degf + 1 - rank");
	close_to($fit->{dispersion}, $e->{dispersion}, "$key: dispersion");
	close_to($fit->{deviance}, $e->{deviance}, "$key: deviance");
}

my %strat = (data => $D{strat}, strata => 'stype', weights => 'pw', fpc => 'fpc');
check('strat_api00',   svyglm(formula => 'api00 ~ ell + meals + mobility', %strat));
check('clus2_api00',   svyglm(formula => 'api00 ~ ell + meals + mobility', data => $D{clus2}, cluster => 'dnum', weights => 'pw'));
check('strat_schwide', svyglm(formula => 'sch.wide ~ ell + meals + mobility', family => 'quasibinomial', %strat));
check('strat_apistu',  svyglm(formula => 'api.stu ~ enroll', %strat));
{
	my $f = svyglm(formula => 'x ~ gt4 - 1', data => $D{fpc}, cluster => 'psuid', strata => 'stratid',
	               weights => 'weight', nest => 1);
	check('fpc_domain', $f);
	my @nm = qw(gt4FALSE gt4TRUE);
	for my $j (0, 1) {
		my ($b, $se, $t) = @{ $DOMAIN[$j] };
		cmp_ok(abs($f->{coefficients}{ $nm[$j] } - $b), '<=', 5e-5, "domain.Rout.save: estimate $nm[$j]");
		cmp_ok(abs($f->{summary}{ $nm[$j] }{'Std. Error'} - $se), '<=', 5e-5, "domain.Rout.save: se $nm[$j]");
		cmp_ok(abs($f->{summary}{ $nm[$j] }{'t value'} - $t), '<=', 5e-3, "domain.Rout.save: t $nm[$j]");
	}
	eval { svyglm(formula => 'x ~ gt4 - 1', data => $D{fpc}, cluster => 'psuid', strata => 'stratid', weights => 'weight') };
	like($@, qr/clusters not nested in strata/, 'psuid repeats across strata: nest => 1 is needed, as svydesign says');
}
check('strat_domain',  svyglm(formula => 'enroll ~ comp.imp - 1', %strat));
check('clus1_api00',   svyglm(formula => 'api00 ~ ell + meals + mobility', data => $D{clus1}, cluster => 'dnum',
                              weights => 'pw', fpc => 'fpc'));
check('clus1_poisson', svyglm(formula => 'api.stu ~ ell + meals', data => $D{clus1}, cluster => 'dnum',
                              weights => 'pw', fpc => 'fpc', family => 'quasipoisson'));
check('strat_nofpc',   svyglm(formula => 'api00 ~ ell + meals + mobility', data => $D{strat}, strata => 'stype', weights => 'pw'));
check('strat_nest',    svyglm(formula => 'api00 ~ ell + meals', data => $D{strat}, strata => 'stype', weights => 'pw',
                              cluster => 'dnum', nest => 1));
check('strat_missing', svyglm(formula => 'api00 ~ acs.k3 + ell', %strat));
check('strat_factor',  svyglm(formula => 'api00 ~ stype + ell', %strat));
{
	# a sampling fraction in place of a population size gives the same fpc
	my %d = %{ $D{strat} };
	my %nh; $nh{$_}++ for @{ $d{stype} };
	$d{frac} = [ map { $nh{ $d{stype}[$_] } / $d{fpc}[$_] } 0 .. $#{ $d{fpc} } ];
	check('strat_api00', svyglm(formula => 'api00 ~ ell + meals + mobility', data => \%d, strata => 'stype',
	                            weights => 'pw', fpc => 'frac'));
	my $b = svyglm(formula => 'api00 ~ ell', %strat);
	is($b->{'n.strata'}, 3, 'three strata');
	is($b->{'n.psu'}, 200, 'no cluster: every school is its own PSU');
	is($b->{degf}, 197, 'degf = PSUs - strata');
}
# ------------------------------------------------------------ errors
{
	my %d = (y => [1, 2, 3, 4], x => [1, 2, 4, 3], s => [qw(a a b b)], u => [1, 2, 3, 3], w => [1, 1, 1, -1]);
	eval { svyglm(formula => 'y ~ x', data => \%d, strata => 's', cluster => 'u') };
	like($@, qr/stratum 2 has only one PSU/, 'a lonely PSU croaks, survey\'s lonely.psu = "fail"');
	eval { svyglm(formula => 'y ~ x', data => \%d, weights => 'w') };
	like($@, qr/negative sampling weight/, 'negative weight');
	eval { svyglm(formula => 'y ~ x', data => \%d, family => 'gamma') };
	like($@, qr/family must be/, 'unknown family');
	eval { svyglm(formula => 'y ~ x', data => { y => [1, 2, 3], x => [1, 2, 3], s => [undef, 'a', 'a'] }, strata => 's') };
	like($@, qr/missing stratum on row '1'/, 'a missing design variable croaks, as svydesign()');
	my @w;
	{
		local $SIG{__WARN__} = sub { push @w, $_[0] };
		svyglm(formula => 'sch.wide ~ ell', %strat, family => 'binomial');
	}
	like($w[0] // '', qr/non-integer #successes/, 'binomial warns, as glm() does inside survey; quasibinomial does not');
}
SKIP: {
	skip 'Test::LeakTrace not installed', 2 unless eval { require Test::LeakTrace; 1 };
	Test::LeakTrace::no_leaks_ok(sub { svyglm(formula => 'api00 ~ ell + meals', %strat) }, 'no leaks');
	Test::LeakTrace::no_leaks_ok(sub {
		eval { svyglm(formula => 'y ~ x', data => { y => [1, 2], x => [1, 2], w => [1, -1] }, weights => 'w') };
	}, 'no leaks: croak');
}
diag(sprintf('worst relative disagreement with survey: %.3g (%s)', $worst, $worst_at));
done_testing();
