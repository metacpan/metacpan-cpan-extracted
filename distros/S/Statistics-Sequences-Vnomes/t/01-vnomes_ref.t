use strict;
use warnings;
use Test::More tests => 18;
use constant EPS => 1e-3;

# Tests output of the module by comparing it to published examples of these tests in Tart (197x), Gatlin (1979) and Rushkin et al. (2001) (from rukhin_delta_2) - see the POD for citation:

use Statistics::Lite qw(count sum);

use Statistics::Sequences::Vnomes;
my $seq = Statistics::Sequences::Vnomes->new();

# Rukhin - page 48

my %refdat = (
    tart => {
        observed_sum => 19, # dinomes
        observed_mean => 2.111,
        chisq => 7.053, # for dinomes
        data => [2, 1, 2, 0, 1, 2, 1, 1, 1, 0, 1, 0, 1, 2, 1, 2, 0, 2, 2, 1],
        states => [0, 1, 2],
    },
    rukhin_delta_2 => {
        psisq => 0.8,
        p_value => 0.67032,
        data => [qw/0 0 1 1 0 1 1 1 0 1/],
        states => [0, 1],
    },
    rukhin_delta_1 => {
        psisq => 1.6,
        p_value => 0.808792,
        data => [qw/0 0 1 1 0 1 1 1 0 1/],
        states => [0, 1],
    },
	gatlin => {
        psisq => 37.842, #37.49443,
        p_value => .3852, #, .45509,
        data => [qw/G A A T A C A G C C T G T C G G T T C T C C G A T G G C A A G T A C T T T A C T G G T T C A G A A T G C G C C C G T A A T C C T T G C A C A G A G G A T C T T A C G C A G T G A A C C G G C T C C G T G G A T T A G C A A C/],
        states => [qw/A C G T/],
    }
);

my $val;

# Tart data test:
eval { $seq->load($refdat{'tart'}->{'data'});};
ok(!$@, do {chomp $@; "Data load failed: $@";});

my @freq = $seq->observed(length => 2, delta => 0, circularize => 0, states => $refdat{'tart'}->{'states'});
my $sum = sum(@freq);
ok(equal($sum, $refdat{'tart'}->{'observed_sum'}), "observed sum of frequences:  $sum != $refdat{'tart'}->{'observed_sum'}");

$val = $seq->psisq(length => 2, delta => 0, circularize => 0, states => [0, 1, 2]);
ok(equal($val, $refdat{'tart'}->{'chisq'}), "psisq $val != $refdat{'tart'}->{'chisq'}");

# Gatlin data:
eval { $seq->load($refdat{'gatlin'}->{'data'});};
ok(!$@, do {chomp $@; "Data load failed: $@";});

$val = $seq->psisq(length => 3, delta => 2, circularize => 0, states => $refdat{'gatlin'}->{'states'}, precision_s => 3);
ok(equal($val, $refdat{'gatlin'}->{'psisq'}), "psisq  $val != $refdat{'gatlin'}->{'psisq'}");

$val = $seq->p_value(length => 3, delta => 2, circularize => 0, states => $refdat{'gatlin'}->{'states'}, precision_s => 3);
ok(equal($val, $refdat{'gatlin'}->{'p_value'}), "p_value $val != $refdat{'gatlin'}->{'p_value'}");

# Rukhin (2006) data:
eval { $seq->load($refdat{'rukhin_delta_2'}->{'data'});};
ok(!$@, do {chomp $@; "Data load failed: $@";});

# - check circularizing for this length:
@freq = $seq->observed(length => 3, delta => 0, circularize => 0);
$sum = sum(@freq);
my $exp_sum = count(@{$refdat{'rukhin_delta_2'}->{'data'}}) - 2;
ok(equal($sum, $exp_sum), "observed sum (no circ) $val != $exp_sum");

@freq = $seq->observed(length => 3, delta => 0, circularize => 1);
$sum = sum(@freq);
$exp_sum = count(@{$refdat{'rukhin_delta_2'}->{'data'}});
ok(equal($sum, $exp_sum), "observed sum (with circ) $val != $exp_sum");

# Test observed()
my $e_obs; # Rukhin et al.'s reported value
my $href = $seq->observed(length => 3, circularize => 1);

# 000
$e_obs = 0; # for r = 000
$val = delete $href->{'000'};
ok(equal($val, $e_obs), "observed() for r = 000 = $val; expected = $e_obs");

# 001
$e_obs = 1;
$val = delete $href->{'001'};
ok(equal($val, $e_obs), "observed() for r = 001 = $val; expected = $e_obs");

# 010
$e_obs = 1;
$val = delete $href->{'010'};
ok(equal($val, $e_obs), "observed() for r = 010 = $val; expected = $e_obs");

# 011
$e_obs = 2;
$val = delete $href->{'011'};
ok(equal($val, $e_obs), "observed() for r = 011 = $val; expected = $e_obs");

# 100
$e_obs = 1;
$val = delete $href->{'100'};
ok(equal($val, $e_obs), "observed() for r = 100 = $val; expected = $e_obs");

# 110
$e_obs = 2;
$val = delete $href->{'110'};
ok(equal($val, $e_obs), "observed() for r = 110 = $val; expected = $e_obs");

# 101
$e_obs = 2;
$val = delete $href->{'101'};
ok(equal($val, $e_obs), "observed() for r = 101 = $val; expected = $e_obs");

# 111
$e_obs = 1; # misprinted as 0 in Rukhin
$val = delete $href->{'111'};
ok(equal($val, $e_obs), "observed() for r = 111 = $val; expected = $e_obs");

# this should account for all the possible v-nomes:
$val = keys %$href;
ok(equal(0, $val), "vnomes remaining = $val; expected = 0");

=pod

Disabled as the published values (for a circularized sequence) correspond to output only without circularization.

my $circ = 1;

# psisq with 2nd backward differencing:
$val = $seq->psisq(length => 3, delta => 2, states => $refdat{'rukhin_delta_2'}->{'states'}, precision_s => 3, circularize => $circ);
ok(equal($val, $refdat{'rukhin_delta_2'}->{'psisq'}), "psisq  $val != $refdat{'rukhin_delta_2'}->{'psisq'}");

$val = $seq->p_value(length => 3, delta => 2, states => $refdat{'rukhin_delta_2'}->{'states'}, precision_s => 3, circularize => $circ);
ok(equal($val, $refdat{'rukhin_delta_2'}->{'p_value'}), "p_value $val != $refdat{'rukhin_delta_2'}->{'p_value'}");

# psisq with 1st backward differencing:
$val = $seq->psisq(length => 3, delta => 1, states => $refdat{'rukhin_delta_1'}->{'states'}, precision_s => 3, circularize => $circ);
ok(equal($val, $refdat{'rukhin_delta_1'}->{'psisq'}), "psisq  $val != $refdat{'rukhin_delta_1'}->{'psisq'}");

$val = $seq->p_value(length => 3, delta => 1, states => $refdat{'rukhin_delta_1'}->{'states'}, precision_s => 3, circularize => $circ);
ok(equal($val, $refdat{'rukhin_delta_1'}->{'p_value'}), "p_value $val != $refdat{'rukhin_delta_1'}->{'p_value'}");

=cut

sub equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
