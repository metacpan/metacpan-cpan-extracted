#!/usr/bin/env perl
# ivreg() against ivreg::ivreg() and Stata's ivreg2.
#
# PROVENANCE
#
# %EXPECT is frozen output of t/ivreg.R.R under R 4.6.1 with ivreg 0.6-8 and
# sandwich 3.1-3 (re-run with `Rscript t/ivreg.R.R`; it also writes the CSV
# files read below).  Each record is summary(fit, diagnostics = TRUE) and
# confint(fit), with vcov. where named:
#
#   kmenta*     ivreg tests/testthat/test-ivreg.R: Kmenta's supply-demand
#               model, Q ~ P + D | D + F + A; and with vcovHC(type = "HC0").
#   cig*        ivreg man/summary.ivreg.Rd: log(packs) ~ log(rincome) |
#               log(rprice) | salestax, the three-part formula; with HC1 as
#               a function, which makes the diagnostics robust too; the
#               two-part form with two instruments; and with case weights.
#   school      ivreg man/ivreg.Rd's SchoolingReturns model, with the
#               quadratics written as I(x^2) where the example has poly().
#   cigsw*      AER ?CigarettesSW / ?ivreg: 1995 alone, and both years with
#               a year effect, clustered by state (vcovCL, HC0 and HC1).
#   griliches   statsmodels' TestIV2SLSSt1 corpus: Griliches (1976),
#               statsmodels' sandbox/regression/tests/griliches76.dta,
#               converted to t/griliches76.csv.  %STATA holds Stata's ivreg2
#               `small` and `small robust` results for it as statsmodels
#               pins them, and ivendog's Wu-Hausman F.
#
# TOLERANCE
#
# 1e-9 relative on everything, against ivreg and against Stata; p-values
# below 1e-3 are compared on the log scale, since a tail probability's
# relative error is its statistic's multiplied by roughly the statistic
# itself (t^2, or F), while log(p)'s is the statistic's own.  Least squares
# here is Householder QR, as in lm.wfit(), so the two agree to rounding: the
# observed worst against ivreg is printed at the end, and was 1.5e-11 on this
# build (a confidence limit of the SchoolingReturns fit, whose quadratics in
# experience and age are the least well-conditioned columns here); against
# Stata it was 2.5e-10, which is about the precision Stata prints.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Spec;
use Stats::LikeR qw(ivreg);

my %EXPECT = (
  kmenta => {
    names => ['Intercept', 'P', 'D'],
    coef => [94.63330386789134, -0.2435565377759468, 0.3139917943481619],
    se => [7.920838311421472, 0.09648429122200206, 0.046943657457939485],
    t => [11.947384878622584, -2.5243128668017487, 6.688694732179567],
    p => [1.0761692713145547e-09, 0.021832399442588375, 3.810851756917412e-06],
    sigma => 1.9663206577519188,
    df => 17,
    r2 => 0.7548467650145644,
    adj => 0.7260052079574544,
    wald => 23.806515042055292,
    wald_p => 1.1778633606915884e-05,
    ci => [77.92179580895538, 111.3448119268273, -0.4471205984123331, -0.03999247713956053, 0.21494933456293, 0.4130342541333938],
    diag_rows => ['Weak instruments', 'Wu-Hausman', 'Sargan'],
    diag_df1 => [2, 1, 1],
    diag_df2 => [16, 16, undef],
    diag_stat => [88.02512827917535, 11.422009178254852, 2.9831191903986887],
    diag_p => [2.3208160961110383e-09, 0.003820767122173772, 0.08413698199508705],
  },
  kmenta_hc0 => {
    names => ['Intercept', 'P', 'D'],
    coef => [94.63330386789134, -0.2435565377759468, 0.3139917943481619],
    se => [5.147453220993823, 0.075899013294179, 0.04292534502545842],
    t => [18.38449031103976, -3.208955257849526, 7.31483449141615],
    p => [1.1798584566110372e-12, 0.005147394231877623, 1.2080526885485996e-06],
    sigma => 1.9663206577519188,
    df => 17,
    r2 => 0.7548467650145644,
    adj => 0.7260052079574544,
    wald => 34.41079724190753,
    wald_p => 1.0549816598510258e-06,
    ci => [83.7731268760703, 105.49348085971239, -0.40368945836618364, -0.08342361718570995, 0.22342723272957984, 0.4045563559667439],
    diag_rows => ['Weak instruments', 'Wu-Hausman', 'Sargan'],
    diag_df1 => [2, 1, 1],
    diag_df2 => [16, 16, undef],
    diag_stat => [142.34001400440164, 21.897585622399024, 2.9831191903986887],
    diag_p => [6.428700672772232e-11, 0.000251194372575922, 0.08413698199508705],
  },
  cig => {
    names => ['Intercept', 'log(rprice)', 'log(rincome)'],
    coef => [9.430658282520014, -1.1433751222046487, 0.21451528489269708],
    se => [1.358366171115875, 0.35948606812411515, 0.26858482669308786],
    t => [6.942648074615173, -3.1805825693636898, 0.798687280789037],
    p => [1.2394773154917949e-08, 0.00266170911568935, 0.4286670733220791],
    sigma => 0.18957466234008485,
    df => 45,
    r2 => 0.41893443473625525,
    adj => 0.393109298502311,
    wald => 6.533672071601593,
    wald_p => 0.003227099781864115,
    ci => [6.69476837393443, 12.166548191105598, -1.8674172302688798, -0.41933301414041746, -0.326442324751826, 0.7554728945372202],
    diag_rows => ['Weak instruments', 'Wu-Hausman', 'Sargan'],
    diag_df1 => [1, 1, 0],
    diag_df2 => [45, 44, undef],
    diag_stat => [45.15776860462702, 1.1020020593623805, undef],
    diag_p => [2.65450820711045e-08, 0.29955903675123413, undef],
  },
  cig_hc1 => {
    names => ['Intercept', 'log(rprice)', 'log(rincome)'],
    coef => [9.430658282520014, -1.1433751222046487, 0.21451528489269708],
    se => [1.2593925528660026, 0.3723026878817881, 0.3117469223485964],
    t => [7.4882595272289345, -3.0710901624424696, 0.6881071456186676],
    p => [1.934709128916856e-09, 0.003611301647052961, 0.49491732659834853],
    sigma => 0.18957466234008485,
    df => 45,
    r2 => 0.41893443473625525,
    adj => 0.393109298502311,
    wald => 8.19114118829424,
    wald_p => 0.0009253655403724328,
    ci => [6.894111473861297, 11.96720509117873, -1.8932312275568062, -0.39351901685249113, -0.413375247882785, 0.8424058176681792],
    diag_rows => ['Weak instruments', 'Wu-Hausman', 'Sargan'],
    diag_df1 => [1, 1, 0],
    diag_df2 => [45, 44, undef],
    diag_stat => [44.73052609751366, 1.179890085462471, undef],
    diag_p => [2.9604168061925032e-08, 0.28329358953987677, undef],
  },
  cig_two => {
    names => ['Intercept', 'log(rprice)', 'log(rincome)'],
    coef => [9.89495554115523, -1.277424133427288, 0.2804048250834284],
    se => [1.0585599476300067, 0.2631985902797489, 0.23856543690824406],
    t => [9.347562755712504, -4.853461152924632, 1.1753790855767443],
    p => [4.120910186998003e-12, 1.4960344598073994e-05, 0.2460246779802507],
    sigma => 0.1878560012387269,
    df => 45,
    r2 => 0.42942241799276304,
    adj => 0.40406341434799686,
    wald => 13.28078578049357,
    wald_p => 2.9307886138811322e-05,
    ci => [7.762906363300102, 12.027004719010359, -1.8075333060583918, -0.7473149607961843, -0.20009062986330578, 0.7609002800301625],
    diag_rows => ['Weak instruments', 'Wu-Hausman', 'Sargan'],
    diag_df1 => [2, 1, 1],
    diag_df2 => [44, 44, undef],
    diag_stat => [244.73375355590272, 3.0678162729438836, 0.3326221419365236],
    diag_p => [1.4440542015415163e-24, 0.08682504624131931, 0.564119140017575],
  },
  school => {
    names => ['Intercept', 'education', 'experience', 'I(experience^2)', 'ethnicityother', 'smsayes', 'southyes'],
    coef => [3.962527177089206, 0.13294725642817298, 0.05596135987863167, -0.0007956581220551566, 0.10314029283019711, 0.10798482394425765, -0.09817517346821672],
    se => [0.5345710131923631, 0.05137940217132253, 0.025994428283256134, 0.0013403007103675029, 0.07737291969578848, 0.04973989927026756, 0.028764510313162663],
    t => [7.412536556042756, 2.5875594267303024, 2.1528213380510555, -0.5936414984343265, 1.333028315794721, 2.1709900005528655, -3.4130660456017456],
    p => [1.6026502230239692e-13, 0.009712408438756035, 0.03141214253165514, 0.5527966292868915, 0.182623631047349, 0.030010008843438185, 0.0006508701875313246],
    sigma => 0.4031655838006819,
    df => 3003,
    r2 => 0.1763739978635419,
    adj => 0.17472839146566688,
    wald => 148.0573368348534,
    wald_p => 6.117113155289985e-165,
    ci => [2.914364783171894, 5.010689571006518, 0.03220487450153707, 0.23368963835480888, 0.004992673763050723, 0.10693004599421262, -0.0034236584559272543, 0.001832342211816941, -0.04856898943783776, 0.254849575098232, 0.010457104322900479, 0.20551254356561482, -0.15457530973758546, -0.04177503719884799],
    diag_rows => ['Weak instruments (education)', 'Weak instruments (experience)', 'Weak instruments (I(experience^2))', 'Wu-Hausman', 'Sargan'],
    diag_df1 => [3, 3, 3, 2, 0],
    diag_df2 => [3003, 3003, 3003, 3001, undef],
    diag_stat => [8.008487875255506, 1612.7070628104566, 1473.0917167971882, 0.840595655866483, undef],
    diag_p => [2.5787092433894e-05, 0, 0, 0.4315550110802847, undef],
  },
  cigsw95 => {
    names => ['Intercept', 'log(rprice)', 'log(rincome)'],
    coef => [9.89495554115523, -1.277424133427288, 0.2804048250834284],
    se => [1.0585599476300067, 0.2631985902797489, 0.23856543690824406],
    t => [9.347562755712504, -4.853461152924632, 1.1753790855767443],
    p => [4.120910186998003e-12, 1.4960344598073994e-05, 0.2460246779802507],
    sigma => 0.1878560012387269,
    df => 45,
    r2 => 0.42942241799276304,
    adj => 0.40406341434799686,
    wald => 13.28078578049357,
    wald_p => 2.9307886138811322e-05,
    ci => [7.762906363300102, 12.027004719010359, -1.8075333060583918, -0.7473149607961843, -0.20009062986330578, 0.7609002800301625],
    diag_rows => ['Weak instruments', 'Wu-Hausman', 'Sargan'],
    diag_df1 => [2, 1, 1],
    diag_df2 => [44, 44, undef],
    diag_stat => [244.7337535559028, 3.0678162729438836, 0.3326221419365236],
    diag_p => [1.4440542015414751e-24, 0.08682504624131931, 0.564119140017575],
  },
  cigsw_cluster => {
    names => ['Intercept', 'log(rprice)', 'log(rincome)', 'yeary1995'],
    coef => [9.550091175870367, -1.1995699378104496, 0.28078936835390983, -0.028417034410484765],
    se => [0.8159645052973987, 0.20736662063077999, 0.2006417518675682, 0.04123596854024565],
    t => [11.70405221534679, -5.784778351315786, 1.3994563232245019, -0.6891322167624168],
    p => [6.464175012234615e-20, 9.916329609943551e-08, 0.16503896742966148, 0.49247444657000283],
    sigma => 0.16617343414310143,
    df => 92,
    r2 => 0.5495317848136291,
    adj => 0.5348426038836387,
    wald => 143.28607608259367,
    wald_p => 1.4895128943572306e-34,
    ci => [7.9295152367814055, 11.170667114959329, -1.6114179456376376, -0.7877219299832616, -0.1177024696393712, 0.6792812063471909, -0.11031522729449392, 0.05348115847352439],
    diag_rows => ['Weak instruments', 'Wu-Hausman', 'Sargan'],
    diag_df1 => [2, 1, 1],
    diag_df2 => [91, 91, undef],
    diag_stat => [225.32871003690354, 2.339131930689141, 0.09766314344481941],
    diag_p => [5.648194504572964e-36, 0.12962866178047797, 0.7546521823238823],
  },
  cigsw_cluster1 => {
    names => ['Intercept', 'log(rprice)', 'log(rincome)', 'yeary1995'],
    coef => [9.550091175870367, -1.1995699378104496, 0.28078936835390983, -0.028417034410484765],
    se => [0.8291615528126278, 0.21072047625538667, 0.20388684245152153, 0.041902900781325074],
    t => [11.517768935951226, -5.692707036010151, 1.3771823869442361, -0.6781638951150949],
    p => [1.564066928215002e-19, 1.4794357793111748e-07, 0.1717974740966779, 0.4993699571325033],
    sigma => 0.16617343414310143,
    df => 92,
    r2 => 0.5495317848136291,
    adj => 0.5348426038836387,
    wald => 138.76125262724733,
    wald_p => 4.9929993502352065e-34,
    ci => [7.903304761287256, 11.196877590453479, -1.6180789924026986, -0.7810608832182007, -0.12414749964542787, 0.6857262363532475, -0.11163981229283532, 0.05480574347186579],
    diag_rows => ['Weak instruments', 'Wu-Hausman', 'Sargan'],
    diag_df1 => [2, 1, 1],
    diag_df2 => [91, 91, undef],
    diag_stat => [215.84118540376994, 2.2406421651821655, 0.09766314344481941],
    diag_p => [2.861284681392866e-35, 0.13788564717400834, 0.7546521823238823],
  },
  cig_weighted => {
    names => ['Intercept', 'log(rprice)', 'log(rincome)'],
    coef => [9.26815890888399, -1.1795727040352564, 0.3420662076027636],
    se => [1.4048059619216362, 0.37672531158287054, 0.2878140221860968],
    t => [6.5974655291226565, -3.1311214504783247, 1.188497367169929],
    p => [4.037481242743724e-08, 0.003057074364623024, 0.24087202742877112],
    sigma => 0.2149584840299484,
    df => 45,
    r2 => 0.41295493702846653,
    adj => 0.38686404534084273,
    wald => 5.669977999575057,
    wald_p => 0.006366639096360349,
    ci => [6.438734460257605, 12.097583357510375, -1.9383364307715087, -0.420808977299004, -0.23762098984968122, 0.9217534050552083],
    diag_rows => ['Weak instruments', 'Wu-Hausman', 'Sargan'],
    diag_df1 => [1, 1, 0],
    diag_df2 => [45, 44, undef],
    diag_stat => [38.99484897643677, 0.8464199109661311, undef],
    diag_p => [1.3521973852931917e-07, 0.3625837288477848, undef],
  },
  griliches => {
    names => ['Intercept', 's', 'iq', 'expr', 'tenure', 'rns', 'smsa', 'yeary67', 'yeary68', 'yeary69', 'yeary70', 'yeary71', 'yeary73'],
    coef => [4.033509894697668, 0.1724253119097814, -0.009098831036219971, 0.04928948974564126, 0.042217092103617626, -0.10179345002195325, 0.12611094946985146, -0.05961710621434885, 0.04867955999311057, 0.1528176332263854, 0.17443605149018218, 0.0916659665637741, 0.09323976497617278],
    se => [0.3181616217675133, 0.02091823230861782, 0.004745269175858417, 0.008225429134622977, 0.008919693389816718, 0.034473365685395316, 0.031196149308128317, 0.05577581734354334, 0.052467962453058826, 0.052010923203462234, 0.060276710442574044, 0.054614358298444556, 0.05767865352084673],
    t => [12.677550083790528, 8.242824219843195, -1.9174530883327596, 5.992330483788249, 4.733020548869461, -2.9528143828752462, 4.042516537032749, -1.0688701493542556, 0.9277958913815721, 2.9381834394397504, 2.8939212211384424, 1.6784224775261123, 1.616538516150923],
    p => [1.7235995868789662e-33, 7.570254102109048e-16, 0.05556250033444665, 3.219967403371173e-09, 2.6473910104460726e-06, 0.0032479412211272136, 5.838098526600749e-05, 0.28547438463901786, 0.35381393704959063, 0.003403360726120562, 0.003915751167729263, 0.09368402236981148, 0.10640126703080698],
    sigma => 0.3799175840115329,
    df => 745,
    r2 => 0.2279825291342349,
    adj => 0.21554734839545753,
    wald => 37.63903370464448,
    wald_p => 1.0488108424394008e-68,
    ci => [3.4089098465667576, 4.658109942828579, 0.13135961443755928, 0.2134910093820035, -0.018414522033674934, 0.0002168599612349907, 0.033141711126581264, 0.06543726836470126, 0.024706366298154203, 0.05972781790908105, -0.16946995275887444, -0.03411694728503206, 0.06486812498615505, 0.18735377395354788, -0.16911358792003528, 0.0498793754913376, -0.05432309536001718, 0.15168221534623832, 0.05071221599930775, 0.25492305045346303, 0.0561036264967132, 0.2927684764836512, -0.015550392946656263, 0.19888232607420447, -0.01999227591269323, 0.2064718058650388],
    diag_rows => ['Weak instruments (s)', 'Weak instruments (iq)', 'Wu-Hausman', 'Sargan'],
    diag_df1 => [4, 4, 2, 2],
    diag_df2 => [743, 743, 743, undef],
    diag_stat => [104.30946266763507, 30.320023169119203, 38.30408858935938, 13.268331373440674],
    diag_p => [1.6678502226204187e-70, 2.1406206711232333e-23, 1.4709919522398738e-16, 0.001314675138655121],
  },
);
# statsmodels 0.14.6 sandbox/regression/tests/results_ivreg2_griliches.py,
# the blocks results_small and results_small_robust, and its hausman dict.
my %STATA = (
  small => {  # ivreg2 lw expr tenure rns smsa dyear* (s iq=med kww age mrt), small
    names => ['s', 'iq', 'expr', 'tenure', 'rns', 'smsa', 'yeary67', 'yeary68', 'yeary69', 'yeary70', 'yeary71', 'yeary73', 'Intercept'],
    coef => [0.17242531190423, -0.00909883103476, 0.04928948974574, 0.04221709210309, -0.10179345001799, 0.12611094946923, -0.05961710621535, 0.04867955999401, 0.15281763322545, 0.17443605148569, 0.09166596656323, 0.09323976497853, 4.0335098946211],
    se => [0.02091823230823, 0.00474526917577, 0.00822542913447, 0.00891969338965, 0.03447336568476, 0.03119614930755, 0.05577581734252, 0.05246796245209, 0.0520109232025, 0.06027671044146, 0.05461435829744, 0.05767865351978, 0.31816162176165],
    r2 => 0.2279825291623523,
    r2_a => 0.2155473484240278,
    rmse => 0.3799175840045295,
    rss => 107.5313411236999,
    F => 37.63903370585438,
    Fp => 1.0488108378e-68,
    sargan => 13.26833137393004, sarganp => 0.0013146751383334,
  },
  small_robust => {  # ivreg2 lw expr tenure rns smsa dyear* (s iq=med kww age mrt), small robust
    names => ['s', 'iq', 'expr', 'tenure', 'rns', 'smsa', 'yeary67', 'yeary68', 'yeary69', 'yeary70', 'yeary71', 'yeary73', 'Intercept'],
    coef => [0.17242531190423, -0.00909883103476, 0.04928948974574, 0.04221709210309, -0.10179345001799, 0.12611094946923, -0.05961710621535, 0.04867955999401, 0.15281763322545, 0.17443605148569, 0.09166596656323, 0.09323976497853, 4.0335098946211],
    se => [0.02091963554158, 0.00492868646034, 0.00811972711081, 0.0095458460509, 0.0340033743578, 0.03107904208149, 0.05216296564028, 0.05024595634484, 0.04834485710231, 0.06165614610562, 0.05594360469515, 0.06137760691084, 0.33794335658841],
    r2 => 0.2279825291623523,
    r2_a => 0.2155473484240278,
    rmse => 0.3799175840045295,
    rss => 107.5313411236999,
    F => 40.08955571761724,
    Fp => 1.50331141073e-72,
  },
  hausman => { WHF => 38.30408858936179, WHFp => 1.47099195224e-16, df => 2, df_r => 743 },  # ivendog after ivreg2
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
		push @{ $d{ $c[$_] } }, ($v[$_] eq 'NA' ? undef : $v[$_]) for 0 .. $#c;
	}
	return \%d;
}
my %D = map { ($_ => read_csv("$_.csv")) } qw(Kmenta CigaretteDemand SchoolingReturns CigarettesSW griliches76);

my (%worst, %worst_at);
sub close_to {
	my ($got, $want, $name, $class, $tol) = @_;
	$class //= 'ivreg'; $tol //= 1e-9;
	my $r = !defined $got ? 9**9**9 : $got == $want ? 0 : abs($got - $want) / (abs($want) || 1);
	($worst{$class}, $worst_at{$class}) = ($r, $name) if $r > ($worst{$class} // 0) && $r < 9**9**9;
	ok($r <= $tol, $name) or diag('got ' . ($got // 'undef') . ", want $want, relative $r");
}
# A p-value's relative error is its statistic's times about t^2 (or the F
# statistic), so a tail probability of 1e-165 carries eight fewer digits than
# the t that made it.  log(p) carries the statistic's own relative accuracy,
# which is what is compared below 1e-3.
#
# R reports a p-value of exactly 0 where it underflows a double (the first
# stage's F of 1612 on 3 and 3003 df in `school`).  A long-double or
# __float128 build carries it on, far below DBL_MIN, so a 0 is checked as "less
# than the smallest normal double", written 2**-1022 because perl 5.10's atof
# misreads decimal literals at the exponent extremes.
sub p_close {
	my ($got, $want, $name, $class, $tol) = @_;
	if ($want == 0) {
		ok(defined $got && $got >= 0 && $got < 2**-1022, "$name (R underflowed to 0)")
			or diag('got ' . ($got // 'undef'));
		return;
	}
	return close_to($got, $want, $name, $class, $tol) if !defined $got || $want >= 1e-3 || $got <= 0;
	return close_to(log($got), log($want), "$name (log scale)", $class, $tol);
}
my %DIAG_KEY = ('Weak instruments' => 'weak', 'Wu-Hausman' => 'wu.hausman', 'Sargan' => 'sargan');
sub check {
	my ($key, $fit) = @_;
	my $e = $EXPECT{$key};
	for my $j (0 .. $#{ $e->{names} }) {
		my $nm = $e->{names}[$j];
		my $s = $fit->{summary}{$nm};
		close_to($fit->{coefficients}{$nm}, $e->{coef}[$j], "$key: coef $nm");
		close_to($s->{'Std. Error'}, $e->{se}[$j], "$key: se $nm");
		close_to($s->{'t value'}, $e->{t}[$j], "$key: t $nm");
		p_close($s->{'Pr(>|t|)'}, $e->{p}[$j], "$key: p $nm");
		close_to($fit->{'conf.int'}{$nm}[0], $e->{ci}[2 * $j], "$key: lower $nm");
		close_to($fit->{'conf.int'}{$nm}[1], $e->{ci}[2 * $j + 1], "$key: upper $nm");
	}
	close_to($fit->{sigma}, $e->{sigma}, "$key: sigma");
	is($fit->{'df.residual'}, $e->{df}, "$key: df.residual");
	close_to($fit->{'r.squared'}, $e->{r2}, "$key: R-squared");
	close_to($fit->{'adj.r.squared'}, $e->{adj}, "$key: adjusted R-squared");
	close_to($fit->{waldtest}{statistic}, $e->{wald}, "$key: Wald test");
	p_close($fit->{waldtest}{'p.value'}, $e->{wald_p}, "$key: Wald p-value");
	return unless $e->{diag_rows};
	for my $r (0 .. $#{ $e->{diag_rows} }) {
		my $row = $e->{diag_rows}[$r];
		my $d;
		if ($row =~ /^Weak instruments(?: \((.*)\))?$/) {
			my $w = $fit->{diagnostics}{weak};
			$d = defined $1 ? $w->{$1} : $w->{ (keys %$w)[0] };
		} else {
			$d = $fit->{diagnostics}{ $DIAG_KEY{$row} };
		}
		if (!defined $e->{diag_stat}[$r]) {
			ok(!defined $d, "$key: no $row test (exactly identified)");
			next;
		}
		close_to($d->{statistic}, $e->{diag_stat}[$r], "$key: $row statistic");
		p_close($d->{'p.value'}, $e->{diag_p}[$r], "$key: $row p-value");
		is($d->{df1} // $d->{df}, $e->{diag_df1}[$r], "$key: $row df1");
		is($d->{df2}, $e->{diag_df2}[$r], "$key: $row df2") if defined $e->{diag_df2}[$r];
	}
}

check('kmenta',     ivreg(formula => 'Q ~ P + D | D + F + A', data => $D{Kmenta}));
check('kmenta_hc0', ivreg(formula => 'Q ~ P + D | D + F + A', data => $D{Kmenta}, vcov => 'HC0'));
check('cig',        ivreg(formula => 'log(packs) ~ log(rincome) | log(rprice) | salestax', data => $D{CigaretteDemand}));
check('cig_hc1',    ivreg(formula => 'log(packs) ~ log(rincome) | log(rprice) | salestax', data => $D{CigaretteDemand},
                          vcov => 'HC1'));
check('cig_two',    ivreg(formula => 'log(packs) ~ log(rprice) + log(rincome) | salestax + cigtax + log(rincome)',
                          data => $D{CigaretteDemand}));
check('cig_weighted', ivreg(formula => 'log(packs) ~ log(rincome) | log(rprice) | salestax', data => $D{CigaretteDemand},
                            weights => 'w'));
check('school',     ivreg(formula => 'log(wage) ~ education + experience + I(experience^2) + ethnicity + smsa + south'
                                   . ' | nearcollege + age + I(age^2) + ethnicity + smsa + south', data => $D{SchoolingReturns}));
{
	my %c95;
	for my $i (0 .. $#{ $D{CigarettesSW}{year} }) {
		next unless $D{CigarettesSW}{year}[$i] eq 'y1995';
		push @{ $c95{$_} }, $D{CigarettesSW}{$_}[$i] for keys %{ $D{CigarettesSW} };
	}
	check('cigsw95', ivreg(formula => 'log(packs) ~ log(rprice) + log(rincome) | log(rincome) + tdiff + rtax', data => \%c95));
	my %cs = %{ $D{CigarettesSW} };
	my $f = 'log(packs) ~ log(rprice) + log(rincome) + year | log(rincome) + year + tdiff + rtax';
	my $a = ivreg(formula => $f, data => \%cs, cluster => 'state');
	check('cigsw_cluster', $a);
	is($a->{'n.clusters'}, 48, 'cigsw: 48 states');
	check('cigsw_cluster1', ivreg(formula => $f, data => \%cs, cluster => 'state', vcov => 'HC1'));
}
{
	my %g = %{ $D{griliches76} };
	my $f = 'lw ~ s + iq + expr + tenure + rns + smsa + year | expr + tenure + rns + smsa + year + med + kww + age + mrt';
	my $m = ivreg(formula => $f, data => \%g);
	check('griliches', $m);
	is_deeply([ sort @{ $m->{endogenous} } ], [qw(iq s)], 'griliches: s and iq are endogenous');
	is_deeply([ sort @{ $m->{instruments} } ], [qw(age kww med mrt)], 'griliches: four excluded instruments');
	my $r = ivreg(formula => $f, data => \%g, vcov => 'HC1');
	for my $pair ([$m, 'small'], [$r, 'small_robust']) {
		my ($fit, $k) = @$pair;
		my $s = $STATA{$k};
		for my $j (0 .. $#{ $s->{names} }) {
			my $nm = $s->{names}[$j];
			close_to($fit->{coefficients}{$nm}, $s->{coef}[$j], "Stata ivreg2 $k: coef $nm", 'Stata');
			close_to($fit->{summary}{$nm}{'Std. Error'}, $s->{se}[$j], "Stata ivreg2 $k: se $nm", 'Stata');
		}
		close_to($fit->{'r.squared'}, $s->{r2}, "Stata ivreg2 $k: r2", 'Stata');
		close_to($fit->{'adj.r.squared'}, $s->{r2_a}, "Stata ivreg2 $k: r2_a", 'Stata');
		close_to($fit->{sigma}, $s->{rmse}, "Stata ivreg2 $k: rmse", 'Stata');
		close_to($fit->{rss}, $s->{rss}, "Stata ivreg2 $k: rss", 'Stata');
		close_to($fit->{waldtest}{statistic}, $s->{F}, "Stata ivreg2 $k: F", 'Stata');
		# Stata prints this p-value to eleven figures
		p_close($fit->{waldtest}{'p.value'}, $s->{Fp}, "Stata ivreg2 $k: Fp", 'Stata');
		if (defined $s->{sargan}) {
			close_to($fit->{diagnostics}{sargan}{statistic}, $s->{sargan}, "Stata ivreg2 $k: Sargan", 'Stata');
			p_close($fit->{diagnostics}{sargan}{'p.value'}, $s->{sarganp}, "Stata ivreg2 $k: Sargan p", 'Stata');
		}
	}
	close_to($m->{diagnostics}{'wu.hausman'}{statistic}, $STATA{hausman}{WHF}, 'Stata ivendog: Wu-Hausman F', 'Stata');
	p_close($m->{diagnostics}{'wu.hausman'}{'p.value'}, $STATA{hausman}{WHFp}, 'Stata ivendog: Wu-Hausman p', 'Stata');
	is($m->{diagnostics}{'wu.hausman'}{df2}, $STATA{hausman}{df_r}, 'Stata ivendog: Wu-Hausman df');
}
# ------------------------------------------------------------ errors
{
	my %d = (y => [1, 2, 3, 4, 5], x => [1, 3, 2, 5, 4], z => [2, 1, 4, 3, 5], g => [qw(a a b b c)]);
	eval { ivreg(formula => 'y ~ x', data => \%d) };
	like($@, qr/needs instruments after '\|'/, 'no instruments');
	eval { ivreg(formula => 'y ~ x | z | z | z', data => \%d) };
	like($@, qr/at most three formula parts/, 'four parts');
	eval { ivreg(formula => 'y ~ x | z', data => \%d, vcov => 'HC3') };
	like($@, qr/vcov must be 'model', 'HC0' or 'HC1'/, 'HC3');
	eval { ivreg(formula => 'y ~ x | z', data => \%d, cluster => 'g', vcov => 'model') };
	like($@, qr/a cluster needs a robust vcov/, 'cluster with the model vcov');
	eval { ivreg(formula => 'y ~ x + offset(z) | z', data => \%d) };
	like($@, qr/offset\(\) is not supported/, 'offset');
	my @w;
	{
		local $SIG{__WARN__} = sub { push @w, $_[0] };
		ivreg(formula => 'y ~ x | x', data => \%d);
	}
	like($w[0] // '', qr/no endogenous variables detected/, 'all exogenous: ivreg\'s warning');
}
SKIP: {
	skip 'Test::LeakTrace not installed', 2 unless eval { require Test::LeakTrace; 1 };
	Test::LeakTrace::no_leaks_ok(sub {
		ivreg(formula => 'log(packs) ~ log(rincome) | log(rprice) | salestax', data => $D{CigaretteDemand}, vcov => 'HC1');
	}, 'no leaks');
	Test::LeakTrace::no_leaks_ok(sub { eval { ivreg(formula => 'y ~ x', data => { y => [1, 2], x => [1, 2] }) } },
	                             'no leaks: croak');
}
diag(sprintf('worst relative disagreement with %s: %.3g (%s)', $_, $worst{$_}, $worst_at{$_})) for sort keys %worst;
done_testing();
