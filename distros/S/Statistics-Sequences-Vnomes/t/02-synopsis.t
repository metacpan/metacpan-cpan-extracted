use strict;
use warnings;
use Test::More tests => 22;
use constant EPS => 1e-3;

# Tests that the POD synopsis example outputs what it says it does, testing most methods in the process:
use Statistics::Sequences::Vnomes 0.20;
my $vnomes = Statistics::Sequences::Vnomes->new();
isa_ok($vnomes, 'Statistics::Sequences::Vnomes');

$vnomes->load(qw/1 0 0 0 1 1 0 1 1 0 0 1 0 0 1 1 1 1 0 1/); # data treated categorically - could also be, e.g., 'a' and 'b'
my $freq_href = $vnomes->observed(length => 3); # returns hashref of frequency distribution for trinomes in the sequence:
my %test_freq = ('011' => 4, '010' => 1, '111' => 2, '000' => 1, '101' => 2, '001' => 3, '100' => 3, '110' => 4);

# test that all the permutations for this length exist in the returned hashref:
foreach my $seq(keys %test_freq) {
    if (!ok(_test_seq($seq, $freq_href) == 1, 'v-nome sequence exists from observed()') ) {
        diag("vnomes sequence '$seq' of length 3 does not exist or is not defined by observed()");
    }
}

while (my($key, $val) = each %$freq_href) {
    ok(equal($val, $test_freq{$key}), "frequency for $key: returned = $val, expected = $test_freq{$key}");
}

my $val;

$val = $vnomes->expected(length => 3, states => [0, 1]); # mean chance expectation for the frequencies (2.5)
ok(equal($val, 2.5), "expected() mean: returned = $val, expected = 2.5");

my %test_vals = (psisq => 3.161, p_value => 0.206);
$val = $vnomes->psisq(length => 3); # Good's "second backward differences" psi-square value, delta^2-psi^2 (3.161)
ok(equal($val, $test_vals{'psisq'}), "psisq default: returned = $val, expected = $test_vals{'psisq'}");

$val = $vnomes->p_value(length => 3); # for psi-square (0.206)
ok(equal($val, $test_vals{'p_value'}), "psisq p-value: returned = $val, expected = $test_vals{'p_value'}");

my $stats_href = $vnomes->stats_hash(length => 3, values => {psisq => 1, p_value => 1}); # include any stat-method (& their options)
while (my($key, $val) = each %$stats_href) {
    ok(equal($val, $test_vals{$key}), "stats_hash() method for $key: returned = $val, expected = $test_vals{$key}");
}

sub _test_seq {
    my ($seq, $freq_href) = @_;
    return ( ! exists $freq_href->{$seq} or ! defined $freq_href->{$seq} ) ? 0 : 1;
}

sub equal {
    return 0 if ! defined $_[0] || ! defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;