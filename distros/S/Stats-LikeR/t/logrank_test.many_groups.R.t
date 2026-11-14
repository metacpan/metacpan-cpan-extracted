#!/usr/bin/env perl
# logrank_test() with many groups, against survival::survdiff().
#
# PROVENANCE
#
# Expected values are frozen output of R 4.6.1 with survival 3.8-12 run as
#   i <- 0:599; tm <- (i*7919) %% 97 + 1; st <- as.integer(i %% 3 != 0)
#   gr <- (i*31 + i %/% 7) %% 40
#   survdiff(Surv(tm, st) ~ gr, rho = 0)   # and rho = 1
# under options(digits=17); `chisq`, `obs`, `exp` are survdiff()'s own fields
# and p is 1 - pchisq(chisq, 39). The data are not from survival's own
# tests: survdiff.Rd's examples have 2-3 groups, which cannot reach the code
# path under test. This is the V update that was rewritten in 0.3419 from
# O(T G^2) to O(N G) by settling each group pair lazily (a change that moves
# V's off-diagonal sums by rounding only); 40 groups with ties and many
# distinct times exercise it where the 2-3 group tests cannot.
#
# TOLERANCE: 1e-12 relative on statistic and p. The old and new builds differed
# from each other by 1e-15 relative on double over these and larger inputs
# (statistic of a 300-group case agreed to 5e-16), so 1e-12 leaves a
# thousandfold headroom for long-double and quadmath perls, where R's
# double-precision solve is the less accurate side. obs and exp are exact sums
# and are held to 1e-13.
require 5.010; use strict; use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR;

my (@tm, @st, @gr);
for my $i (0 .. 599) {
	push @tm, ($i * 7919) % 97 + 1;
	push @st, ($i % 3 != 0) ? 1 : 0;
	push @gr, 'g' . ((($i * 31) + int($i / 7)) % 40);
}
sub close_to { my ($got, $want, $tol, $name) = @_; cmp_ok(abs($got - $want), '<=', $tol * abs($want), $name) }
{
	my $r = logrank_test(\@tm, \@st, \@gr, rho => 0);
	my @obs = (12, 7, 8, 6, 10, 9, 12, 9, 12, 12, 13, 9, 12, 9, 11, 6, 8, 6, 12, 9, 12, 9, 15, 11, 12, 9, 12, 9, 8, 6, 8, 9, 12, 9, 12, 10, 15, 9, 12, 9);
	my @exp = (17.502372497289787, 11.395426454633451, 12.708359094345827, 5.6789870024094924, 11.169612152743186, 5.8725227673423435, 7.7201587898197772, 6.7334753894192341, 8.2276043137789365, 7.606103468043238, 9.4694681354243233, 8.0545576048367629, 9.8816441305682119, 9.0261231226196905, 12.944398989363638, 9.877507505514231, 12.16571916183163, 7.9851063135727207, 17.455037048408158, 13.754602588690076, 13.249461229880049, 10.923187024269303, 12.85662905583203, 8.5047967769150787, 7.0659306310088361, 6.2053325153898999, 8.7484231930041823, 6.0740036558110209, 8.4173953244538176, 7.3674443668961063, 8.9928632368604777, 7.2751949690014994, 11.93695851704125, 8.9135258132279436, 10.89051886386498, 7.5734224584287846, 15.008424544256226, 11.260581953608817, 13.859121749732331, 9.6479975898625909);
	is($r->{parameter}, 39, 'rho 0: df');
	close_to($r->{statistic}, 37.845911565170752, 1e-12, 'rho 0: chisq');
	close_to($r->{p_value}, 0.52241818098525949, 1e-12, 'rho 0: p');
	is(scalar(@{$r->{observed}}), 40, 'rho 0: 40 groups');
	my @gnames = @{$r->{groups}};
	my %idx; @idx{@gnames} = (0 .. $#gnames);
	# R orders groups numerically (gr=0..39); the module orders them as it meets them
	for my $k (0 .. 39) {
		my $j = $idx{"g$k"};
		close_to($r->{observed}[$j], $obs[$k], 1e-13, "rho 0: obs g$k");
		close_to($r->{expected}[$j], $exp[$k], 1e-13, "rho 0: exp g$k");
	}
}
{
	my $r = logrank_test(\@tm, \@st, \@gr, rho => 1);
	my @obs = (6.1108192531015817, 3.7370863437310762, 4.7541671770376341, 4.0326509937711714, 6.95147000938523, 6.2107096108881343, 8.071369084538027, 5.8602259776405781, 7.8849478401179995, 8.1147793627362219, 8.2567655485144176, 5.0069616580775769, 7.2750273868738571, 5.4932554850825834, 6.5470889857524313, 3.1706013775686492, 4.4730292730676346, 3.5380881963162327, 6.3196850592799647, 4.463185050850714, 7.0328784002952318, 5.1713941700422517, 8.9551195573667624, 6.9138186316081489, 8.2827774535106791, 6.0158382853135137, 8.0956894040854319, 6.5377838481696608, 5.1846324281634359, 3.626500559672845, 5.0585299457283766, 6.0953986762516141, 7.2514555476162386, 4.8156094825868339, 7.0396393250648206, 6.1582994801931727, 8.0446413864540354, 4.6809182874485646, 6.3439470735228376, 5.3038217955567388);
	my @exp = (9.2065792027154885, 5.8150880057375653, 6.6531625674007442, 4.0370167651163928, 6.6009057062032168, 4.17080690392166, 5.4151214767091265, 4.5785104854886312, 5.6673944250453063, 5.221649914265396, 6.3712314919911641, 5.1532109961917705, 6.4185867313404987, 5.7993704633561132, 8.0302588225394, 5.7825359107598286, 7.2299985648967136, 5.0192087881326035, 9.5922744804961475, 6.5232310924371051, 7.1749590452327645, 5.683085921684313, 7.3871627036489214, 4.7957173075903023, 5.0576348840607395, 4.3108616295172872, 6.0141327090079182, 4.4359562026721955, 5.7714040262895203, 4.8657134775857838, 6.0341438083565029, 5.0902794678296459, 7.6918582963627715, 5.4708130495854412, 6.8151801112205819, 4.8925628316012517, 8.9208777874775596, 6.1350147549939349, 7.6695923725167559, 5.3775142310038451);
	is($r->{parameter}, 39, 'rho 1: df');
	close_to($r->{statistic}, 28.722985246179313, 1e-12, 'rho 1: chisq');
	close_to($r->{p_value}, 0.88643802386795922, 1e-12, 'rho 1: p');
	is(scalar(@{$r->{observed}}), 40, 'rho 1: 40 groups');
	my @gnames = @{$r->{groups}};
	my %idx; @idx{@gnames} = (0 .. $#gnames);
	# R orders groups numerically (gr=0..39); the module orders them as it meets them
	for my $k (0 .. 39) {
		my $j = $idx{"g$k"};
		close_to($r->{observed}[$j], $obs[$k], 1e-13, "rho 1: obs g$k");
		close_to($r->{expected}[$j], $exp[$k], 1e-13, "rho 1: exp g$k");
	}
}
done_testing;
