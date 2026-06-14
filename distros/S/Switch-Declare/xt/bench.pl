#!/usr/bin/perl
# Substantiates the performance claims in the POD:
#   * Switch::Declare chain mode is on par with a hand-written if/elsif chain.
#   * For many string arms, a hand-written hash dispatch is faster (this is the
#     "dispatch mode" optimisation documented as future work).
# Run:  perl -Mblib xt/bench.pl
use strict;
use warnings;
use Benchmark qw(cmpthese);
use Switch::Declare;

# ---- numeric, few arms -------------------------------------------------
my @vals = (1 .. 6);
my $i = 0;

sub sw_few {
    my $v = $vals[$i++ % @vals];
    return switch ($v) {
        case 1 { "a" } case 2 { "b" } case 3 { "c" }
        case 4 { "d" } case 5 { "e" } default { "z" }
    };
}
sub if_few {
    my $v = $vals[$i++ % @vals];
    return $v == 1 ? "a" : $v == 2 ? "b" : $v == 3 ? "c"
         : $v == 4 ? "d" : $v == 5 ? "e" : "z";
}

print "== numeric, 5 arms + default ==\n";
cmpthese(-2, { 'switch' => \&sw_few, 'if/elsif' => \&if_few });

# ---- string, many arms -------------------------------------------------
my @keys = map { "k$_" } 0 .. 19;
my $j = 0;

sub sw_many {
    my $v = $keys[$j++ % @keys];
    return switch ($v) {
        case "k0"{0} case "k1"{1} case "k2"{2} case "k3"{3} case "k4"{4}
        case "k5"{5} case "k6"{6} case "k7"{7} case "k8"{8} case "k9"{9}
        case "k10"{10} case "k11"{11} case "k12"{12} case "k13"{13}
        case "k14"{14} case "k15"{15} case "k16"{16} case "k17"{17}
        case "k18"{18} case "k19"{19} default { -1 }
    };
}
sub hash_many {
    my %dispatch = map { ("k$_" => sub { $_ }) } 0 .. 19;
    my $v = $keys[$j++ % @keys];
    my $h = $dispatch{$v};
    return defined $h ? $h->() : -1;
}
sub if_many {
    my $v = $keys[$j++ % @keys];
    return $v eq "k0" ? 0 : $v eq "k1" ? 1 : $v eq "k2" ? 2 : $v eq "k3" ? 3
         : $v eq "k4" ? 4 : $v eq "k5" ? 5 : $v eq "k6" ? 6 : $v eq "k7" ? 7
         : $v eq "k8" ? 8 : $v eq "k9" ? 9 : $v eq "k10"?10 : $v eq "k11"?11
         : $v eq "k12"?12 : $v eq "k13"?13 : $v eq "k14"?14 : $v eq "k15"?15
         : $v eq "k16"?16 : $v eq "k17"?17 : $v eq "k18"?18 : $v eq "k19"?19 : -1;
}

# switch(chain) should match hand if/elsif (both O(n)); hand %dispatch is O(1)
# and wins at this arm count - the future "dispatch mode" optimisation.
print "\n== string, 20 arms ==\n";
cmpthese(-2, {
    'switch'         => \&sw_many,
    'if/elsif'       => \&if_many,
    'hand %dispatch' => \&hash_many,
});
