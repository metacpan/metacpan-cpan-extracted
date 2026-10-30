#!/usr/bin/env perl
#
# Cross-validation of prcomp() against R's stats::prcomp(), for what 0.331
# changed in it.
#
# Provenance: R 4.6.1 prcomp.default (src/library/stats/R/prcomp.R), run by
# t/prcomp.R.R, which is committed next to this file and prints the tables
# below at options(digits = 17); re-run it to regenerate them.  The test never
# calls R.  The cases:
#
#   * README's own example, matrix(c(2,4,6,4,2,6), 3), plain and scaled.
#   * center = FALSE with scale. = TRUE, where R's scale() divides each column
#     by sqrt(sum(x^2)/(n-1)).  0.33 divided by the sd about the mean instead:
#     scale (2.5, 2.94) where R has (5, 6.48).
#   * rank. = 1.  R returns every one of the min(n, p) sdev and cuts only the
#     rotation and the scores; 0.33 cut sdev too.
#   * tests/reg-tests-1a.R's "prcomp(tol=1e-6)" case, on R's own data (x is
#     set.seed(16); matrix(runif(30), ncol = 10), carried here exactly):
#     stopifnot(length(s$sdev) == 3, ncol(s$rotation) == 2).
#   * a 20 x 4 matrix whose third column is exactly the sum of the first two.
#     Its last singular value is 0 in exact arithmetic; R's SVD puts it at
#     about NV_EPSILON * |X| (5.3e-17 here).  0.33 took sdev from the
#     eigenvalues of X'X, which squares the singular values, and put it near
#     sqrt(NV_EPSILON) * |X| -- 1.3e-8 on the scaled matrix.
#   * prcomp.Rd's tol/rank. example in kind: correlated columns, Z = X B with
#     B[i, j] = 1 on and above the diagonal (each row a random walk), 200 x 32,
#     exact in double and rebuilt here bit for bit.  The Rd asserts that rank. = 3 returns the
#     same sdev as the full fit; that, and the number of components R keeps
#     at tol = 0.1, are pinned.
#
# Signs: a principal component is defined only up to sign, R's come from
# LAPACK's dgesdd, and nothing here reproduces dgesdd's choice, so rotation
# and scores are compared after matching each column's sign to R's -- every
# ratio within a column is still pinned.  t/tukey_aov_prcomp.R.t does the same.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR 'prcomp';

# Tolerances, against the worst disagreement measured on a double build:
#   sdev      3.5e-15 relative (the smallest of Z's 32) -- both sides are
#             backward-stable SVDs, so this is a few ulp of sdev[0]; 1e-13
#             leaves room for the long-double and __float128 builds.
#   rotation  1.0e-15 absolute, scores 2.6e-15 relative to the column's
#             largest score.  A singular vector can move by eps / (the gap to
#             its neighbouring singular value), which is why 1e-11 is looser
#             than the observed error by more than the sdev bound is.
# The zero singular value is compared against the first, not against R's
# noise: both sides only promise that it is a few NV_EPSILON of sdev[0].
my ($TOL_SDEV, $TOL_VEC) = (1e-13, 1e-11);

my %R = (
	readme => {
		sdev => [ 2.4494897427831779, 1.4142135623730949 ],
		rotation => [ [ 0.70710678118654757, -0.70710678118654735 ], [ 0.70710678118654735, 0.70710678118654757 ] ],
		x => [ [ -1.4142135623730951, 1.4142135623730947 ], [ -1.4142135623730947, -1.4142135623730951 ], [ 2.8284271247461898, 4.4408920985006262e-16 ] ],
		center => [ 4, 4 ],
	},
	readme_scaled => {
		sdev => [ 1.2247448713915889, 0.70710678118654746 ],
		rotation => [ [ 0.70710678118654757, -0.70710678118654735 ], [ 0.70710678118654735, 0.70710678118654757 ] ],
		x => [ [ -0.70710678118654757, 0.70710678118654735 ], [ -0.70710678118654735, -0.70710678118654757 ], [ 1.4142135623730949, 2.2204460492503131e-16 ] ],
		scale => [ 2, 2 ],
		center => [ 4, 4 ],
	},
	nocenter_scale => {
		sdev => [ 1.4098019150779262, 0.11161792079505777 ],
		rotation => [ [ -0.70710678118654746, 0.70710678118654768 ], [ -0.70710678118654768, -0.70710678118654746 ] ],
		x => [ [ -0.35963924647330192, -0.076796533998682831 ], [ -0.96980879430190947, -0.12128065687805228 ], [ -1.002121205421223, 0.1292496444772534 ], [ -1.9719299997231321, 0.0079689875992010606 ] ],
		scale => [ 5, 6.4807406984078604 ],
	},
	nocenter => {
		sdev => [ 8.1614745152016877, 0.62476694671964894 ],
		rotation => [ [ -0.60962176312864269, 0.79269244093779856 ], [ -0.79269244093779856, -0.60962176312864269 ] ],
		x => [ [ -2.1950066450042396, -0.42655108531948682 ], [ -5.7923274940749208, -0.67003149282981767 ], [ -5.6092568162657646, 0.73228271123662347 ], [ -11.401584310340686, 0.062251218406805364 ] ],
	},
	rank1 => {
		sdev => [ 3.8160003243491967, 0.59565778030132421 ],
		rotation => [ [ 0.64416483243439704 ], [ 0.76488670314940432 ] ],
		x => [ [ -4.0661133986428046 ], [ -0.48312362432579781 ], [ -0.60384549504080509 ], [ 5.1530825180094073 ] ],
		center => [ 3.75, 5 ],
	},
	regtest_tol => {
		sdev => [ 0.82282604575227369, 0.59695682649181492, 9.2283375928914261e-17 ],
		rotation => [ [ -0.25081166455420717, 0.12590524725818403 ], [ 0.29516958574892466, -0.41024579379020193 ], [ 0.53783845963457211, 0.1392453772792045 ], [ 0.19682010537274133, 0.26741142217356956 ], [ 0.31452210499183303, -0.054473868527660098 ], [ 0.38006894058805368, -0.06109442694064713 ], [ -0.21035798852422072, 0.71342899742192689 ], [ -0.215921886386086, -0.13794445638043901 ], [ 0.37220492094832791, 0.32761726791154167 ], [ -0.22175270092713054, -0.28793315298838917 ] ],
		x => [ [ -0.94097544618877005, -0.095393210501050887 ], [ 0.58435874144719768, -0.54351617728881141 ], [ 0.35661670474157237, 0.63890938778986239 ] ],
		center => [ 0.45911294446947676, 0.46804776275530457, 0.59371312242001295, 0.35007386018211645, 0.44798080902546644, 0.59200952101188398, 0.58684031261752045, 0.5957626760161171, 0.60931058522934711, 0.73785365729903185 ],
	},
	collinear => {
		sdev => [ 0.51471711395759545, 0.32785535833435425, 0.21575958492535768, 5.3402420758107278e-17 ],
		rotation => [ [ 0.26306274195808693, 0.55679747945558089, -0.53613545614151625, -0.57735026918962584 ], [ 0.52492179498141345, -0.34333242577120621, 0.52272996971114727, -0.57735026918962584 ], [ 0.78798453693950055, 0.21346505368437454, -0.013405486430369207, 0.57735026918962584 ], [ -0.18529833375188473, 0.72562530492086519, 0.66267069074109264, 6.3317406873153459e-17 ] ],
		x => [ [ -0.91224745964436704, 0.007589692763612127, 0.24908605995172745, 2.1503049714238586e-17 ], [ -0.13564416225588283, -0.03841272796865644, -0.38914332744770169, -2.6235191179976847e-18 ], [ 0.90202334944087659, -0.096438361985258486, -0.059281020789395331, 3.8009882206542581e-17 ], [ -0.42270863446860285, 0.42422421638832658, 0.23089394516095374, 6.3827439821408755e-18 ], [ -0.57389864360270637, -0.20409430231189701, -0.3810408295676419, -1.8631660962605711e-17 ], [ 0.049163213970159235, 0.42030903167221173, -0.1443534598565257, 1.2677297276093797e-17 ], [ 0.83436110422601528, 0.27183783536580031, 0.36629175851142126, 1.8069363434526864e-17 ], [ 0.37205739385211078, -0.32712492284542982, -0.032399109419323641, 7.0012897918733284e-18 ], [ -0.27276002449004261, -0.3427696540679892, -0.17480461175006323, -1.9882821269928919e-17 ], [ 0.66045861761145042, -0.10551654641222856, -0.12499280843397495, 3.766979847821998e-17 ], [ 0.36824281152367405, 0.49575099913796294, -0.23415105241855161, 6.4143191204832497e-17 ], [ -0.32840892329631399, 0.58355638698901879, 0.014359550897040496, 4.5144718653951371e-17 ], [ -0.29436404517339121, 0.38487694869731542, -0.044068321266356458, 3.3165462553178823e-17 ], [ -0.33160332057041758, 0.013677202890235871, 0.066296839257620838, 3.5056265084577035e-17 ], [ 0.59844803348380526, 0.066797805690827647, -0.031307834729742454, 5.0245167250512543e-17 ], [ -0.71744443432248306, -0.16564916975521254, 0.028654689568701791, 5.7520253825140924e-17 ], [ -0.032502965739206649, -0.57372840130470693, 0.089461549113482974, -2.2224761489968652e-17 ], [ -0.24630120784538756, -0.31979596536360766, 0.19713311584754192, -3.5317501956911082e-18 ], [ 0.13551956503863521, -0.20797502922574979, 0.39527643076196672, 2.6256572144450118e-17 ], [ 0.34760973226207514, -0.28711503835457486, -0.02191156339118025, 9.5664099586247693e-18 ] ],
		center => [ -0.0020568847656250002, -0.052945709228515624, -0.055002593994140626, -0.09096527099609375 ],
	},
	collinear_scaled => {
		sdev => [ 1.4515867175419521, 1.1538985604901451, 0.74927572598780423, 1.8000314039110983e-16 ],
		rotation => [ [ 0.37078740354596568, 0.66033639231915209, -0.48069285799400124, 0.44204855686239647 ], [ 0.58350468728554117, -0.31881851400259648, 0.51211808011476201, 0.54370222278794234 ], [ 0.67443125911910118, 0.16618109334873923, 0.092441087321157522, -0.71342901981299012 ], [ -0.25919386183022908, 0.65931361909300867, 0.70577906859583972, -5.2041704279304213e-17 ] ],
		x => [ [ -2.6709631806139678, -0.1271962229687168, 0.77744379237928918, -6.0219465620335532e-17 ], [ -0.21583298805318568, 0.028338094812699111, -1.3638931978520215, 3.2376780041583223e-16 ], [ 2.5742381361450608, -0.26769929052215813, -0.13894887761211494, -1.7303215867429251e-16 ], [ -1.3360539060037138, 1.3660834774322221, 0.83610164875104676, 7.0928811995314778e-17 ], [ -1.4324231790850201, -0.57792337380641046, -1.406762864496635, 3.8524502545442003e-16 ], [ 0.14762019565748027, 1.5394081834172872, -0.41725533403552134, 2.4205288202346356e-16 ], [ 2.1632728081963286, 0.83482154680541765, 1.3923057730366781, -2.7264800419105812e-16 ], [ 1.0996259287582231, -1.114661270479077, -0.13732046608325132, -2.7494436113259954e-16 ], [ -0.65386345029019899, -1.1393162336525793, -0.69180334722093795, 1.7085145261858368e-19 ], [ 1.9228458864984548, -0.2828250883714758, -0.38996946283746114, -2.8310205388956091e-16 ], [ 1.0735721685330535, 1.8589452169745773, -0.68413848409568434, 3.0889280923263098e-16 ], [ -1.0001572830655452, 2.0239825812222496, 0.12594050359264886, 2.177480376269218e-16 ], [ -0.8562758657461722, 1.3543985065287183, -0.10908749762496273, 1.6802931492383757e-16 ], [ -0.96216624504850379, 0.002631404245624025, 0.20083876948737719, -2.0445640238135621e-17 ], [ 1.6888373896170228, 0.27753312300289429, -0.040554127630343273, -2.0729717395593739e-16 ], [ -2.0106852679901999, -0.62893155772304521, 0.002297082502861883, -5.6265081552574643e-18 ], [ -0.059560133865090903, -2.052670607255767, 0.20111129519483151, -2.7082628206921798e-16 ], [ -0.7362690040105424, -1.2196961891188702, 0.59972400539283499, -2.6766506100767472e-16 ], [ 0.24255615013637316, -0.89508838673323388, 1.3400065688842202, -4.5932366725240799e-16 ], [ 1.0216818402301437, -0.98013391381035619, -0.096035779732855708, -2.2661684979180023e-16 ] ],
		scale => [ 0.25502767711596191, 0.31367394547010563, 0.4115931222611392, 0.29348881311206371 ],
		center => [ -0.0020568847656250002, -0.052945709228515624, -0.055002593994140626, -0.09096527099609375 ],
	},
	Z => { sdev => [ 6.3272828411727984, 2.0089181517441479, 1.1926294392020893, 0.90356506986619656, 0.74156060623384845, 0.53688289997243011, 0.44817118862389366, 0.39648255196520288, 0.36567180359727741, 0.31372628760036131, 0.2903341938761404, 0.28404376918520269, 0.25427849277463022, 0.23778699389217611, 0.2328426026886827, 0.21498239011987627, 0.21033604075417042, 0.20095016029443433, 0.18855724873973817, 0.18171958780555636, 0.17514467110463058, 0.16143635519398855, 0.15575857143888064, 0.15264991484257034, 0.14466429771389377, 0.1373780042507054, 0.13361619049149587, 0.12792110182788771, 0.12567258027172964, 0.11800576509481839, 0.11129312446942465, 0.10422498299076728 ], tol_ncol => 5, rank3_ncol => 3 },
);
# reg-tests-1a.R's x, set.seed(16); matrix(runif(30), ncol = 10), row by row
my @RT = ([ '6152908393414656:-53', '8266270411587584:-55', '5356565133524992:-56', '5021035829133312:-55', '5664435511230464:-55', '8654188149997568:-55', '6455691480924160:-53', '7314736012066816:-53', '8208168110784512:-55', '8772871308443648:-53' ],
	[ '8795256870928384:-55', '7777787857338368:-53', '7496886608986112:-53', '5760013406568448:-54', '5957199270510592:-53', '7631907458121728:-53', '5487587993059328:-56', '4904977340301312:-53', '5843388985245696:-53', '6888407443701760:-53' ],
	[ '8108485405310976:-54', '5606085838766080:-54', '7876619930697728:-53', '5324289377042432:-53', '4731849079259136:-53', '6201588653752320:-53', '8715722899324928:-53', '7757492083752960:-54', '8569114534608896:-53', '8553411968499712:-54' ]);

sub lcg_make {	# t/prcomp.R.R's lcg(): the 16-bit Lehmer generator, centred
	my $s = 12345;
	return sub {
		my ($n) = @_;
		my @u;
		for (1 .. $n) { $s = (75 * $s + 74) % 65537; push @u, ($s % 65536) / 65536 - 0.5 }
		return @u;
	};
}
sub dy { my ($m, $e) = split /:/, $_[0]; return $m * 2 ** $e }

my $lcg = lcg_make();
my @a = $lcg->(20); my @b = $lcg->(20); my @c4 = $lcg->(20);
my $coll = [ map { [ $a[$_], $b[$_], $a[$_] + $b[$_], $c4[$_] ] } 0 .. 19 ];
my @X = map { [ $lcg->(32) ] } 1 .. 200;
my $Z = [ map { my $x = $_; my $s = 0; [ map { $s += $x->[$_] } 0 .. 31 ] } @X ];	# X %*% B, B upper-triangular ones
my $rt = [ map { [ map { dy($_) } @$_ ] } @RT ];
my $readme = [ [ 2, 4 ], [ 4, 2 ], [ 6, 6 ] ];
my $m4 = [ [ 1, 2 ], [ 3, 5 ], [ 4, 4 ], [ 7, 9 ] ];

my %CALL = (
	readme           => sub { prcomp($readme) },
	readme_scaled    => sub { prcomp($readme, scale => 1) },
	nocenter_scale   => sub { prcomp($m4, center => 0, scale => 1) },
	nocenter         => sub { prcomp($m4, center => 0) },
	rank1            => sub { prcomp($m4, rank => 1) },
	regtest_tol      => sub { prcomp($rt, tol => 1e-6) },
	collinear        => sub { prcomp($coll) },
	collinear_scaled => sub { prcomp($coll, scale => 1) },
);

sub relerr { my ($g, $w) = @_; return $w == 0 ? abs($g) : abs($g - $w) / abs($w) }
my %worst = (sdev => 0, rotation => 0, x => 0);

for my $label (sort keys %CALL) {
	my $want = $R{$label};
	my $got  = $CALL{$label}->();
	my $ns   = scalar @{ $want->{sdev} };
	is(scalar @{ $got->{sdev} }, $ns, "$label: $ns sdev, as R returns");
	my $s0 = $want->{sdev}[0];
	for my $k (0 .. $ns - 1) {
		my $w = $want->{sdev}[$k];
		if ($w < 1e-12 * $s0) {	# R's rounding noise for an exact zero
			cmp_ok($got->{sdev}[$k], '<', 64 * 2.220446049250313e-16 * $s0,
				"$label: sdev[$k] is a zero singular value, within 64 eps of sdev[0], as R's is");
			next;
		}
		my $e = relerr($got->{sdev}[$k], $w);
		$worst{sdev} = $e if $e > $worst{sdev};
		ok($e <= $TOL_SDEV, "$label: sdev[$k] = $w") or diag("got $got->{sdev}[$k], rel err $e");
	}
	my $nc = scalar @{ $want->{rotation}[0] };
	is(scalar @{ $got->{rotation}[0] }, $nc, "$label: rotation has R's $nc columns");
	for my $k (0 .. $nc - 1) {
		next if $want->{sdev}[$k] < 1e-12 * $s0;	# a null direction: any unit vector in it will do
		my $dot = 0;
		$dot += $got->{rotation}[$_][$k] * $want->{rotation}[$_][$k] for 0 .. $#{ $want->{rotation} };
		my $sg = $dot < 0 ? -1 : 1;
		my $e = 0;
		for my $r (0 .. $#{ $want->{rotation} }) {
			my $d = abs($sg * $got->{rotation}[$r][$k] - $want->{rotation}[$r][$k]);
			$e = $d if $d > $e;
		}
		$worst{rotation} = $e if $e > $worst{rotation};
		ok($e <= $TOL_VEC, "$label: rotation column $k matches R's up to sign") or diag("max abs err $e");
		next unless $want->{x};
		my ($big, $ex) = (0, 0);
		for my $i (0 .. $#{ $want->{x} }) { $big = abs($want->{x}[$i][$k]) if abs($want->{x}[$i][$k]) > $big }
		for my $i (0 .. $#{ $want->{x} }) {
			my $d = abs($sg * $got->{x}[$i][$k] - $want->{x}[$i][$k]) / ($big || 1);
			$ex = $d if $d > $ex;
		}
		$worst{x} = $ex if $ex > $worst{x};
		ok($ex <= $TOL_VEC, "$label: scores column $k match R's up to sign") or diag("max rel err $ex");
	}
	for my $key (qw(scale center)) {
		next unless $want->{$key};
		my $e = 0;
		for my $j (0 .. $#{ $want->{$key} }) {
			my $d = relerr($got->{$key}[$j], $want->{$key}[$j]);
			$e = $d if $d > $e;
		}
		ok($e <= $TOL_SDEV, "$label: $key matches R's") or diag("rel err $e");
	}
}

# reg-tests-1a.R, verbatim in substance: stopifnot(length(s$sdev) == 3,
# ncol(s$rotation) == 2) for prcomp(x, tol = 1e-6) on that 3 x 10 x.
{
	my $s = prcomp($rt, tol => 1e-6);
	is(scalar @{ $s->{sdev} }, 3, 'reg-tests-1a prcomp(tol=1e-6): length(sdev) == 3');
	is(scalar @{ $s->{rotation}[0] }, 2, 'reg-tests-1a prcomp(tol=1e-6): ncol(rotation) == 2');
	is(scalar @{ $s->{x}[0] }, 2, '... and the scores are cut with it');
}

# prcomp.Rd: rank. = 3 returns the full fit's sdev, and tol keeps R's count.
{
	my $full = prcomp($Z);
	my $pz3  = prcomp($Z, rank => 3);
	my $ptol = prcomp($Z, tol => 0.1);
	is(scalar @{ $ptol->{rotation}[0] }, $R{Z}{tol_ncol}, "prcomp.Rd: tol = 0.1 keeps R's $R{Z}{tol_ncol} components");
	is(scalar @{ $pz3->{rotation}[0] }, $R{Z}{rank3_ncol}, 'prcomp.Rd: rank = 3 keeps 3');
	is_deeply($pz3->{sdev}, $full->{sdev}, 'prcomp.Rd: rank = 3 returns the full fit\'s sdev, exactly');
	is(scalar @{ $ptol->{sdev} }, 32, '... as does tol, all 32 of them');
	my $e = 0;
	for my $k (0 .. 31) { my $d = relerr($full->{sdev}[$k], $R{Z}{sdev}[$k]); $e = $d if $d > $e }
	$worst{sdev} = $e if $e > $worst{sdev};
	ok($e <= $TOL_SDEV, 'prcomp.Rd-style Z: all 32 sdev match R') or diag("rel err $e");
}

diag(sprintf 'worst vs R: sdev %.3g, rotation %.3g, scores %.3g', @worst{qw(sdev rotation x)});
done_testing();
