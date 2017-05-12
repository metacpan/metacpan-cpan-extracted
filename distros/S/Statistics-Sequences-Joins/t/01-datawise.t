use strict;
use warnings;
use Test::More tests => 18;
use constant EPS => 1e-2;

use Statistics::Sequences::Joins 0.20;

my $seq = Statistics::Sequences::Joins->new();
isa_ok($seq, 'Statistics::Sequences::Joins');

my %refdat = (
    chimps => {
        observed  => 4, expected => 3.50, variance => 1.75, z_value => 0, p_value => 1.00000, data => [qw/ban ban che ban che ban ban ban/],
    },
    mice => {
        observed  => 1, expected => 3.50, variance => 1.75, z_value => -1.512, p_value => 0.13057, data => [qw/ban che che che che che che che/],
    },
    matched => {
        observed  => 5, expected => 3.50, variance => 1.75, z_value => 0.7559, p_value => .44970,
        data => [qw/1 0 1 0 1 0 0 0/],
    },
);

my $val;
$val = $seq->observed(data => $refdat{'mice'}->{'data'});
ok(equal($val, $refdat{'mice'}->{'observed'}), "joinstat_observed  observed  $val != $refdat{'mice'}->{'observed'}");

$val = $seq->expected(data => $refdat{'mice'}->{'data'}, prob => .5);
ok(equal($val, $refdat{'mice'}->{'expected'}), "expected  observed  $val != $refdat{'mice'}->{'expected'}");

$val = $seq->variance(data => $refdat{'mice'}->{'data'}, prob => .5);
ok(equal($val, $refdat{'mice'}->{'variance'}), "variance  observed  $val != $refdat{'mice'}->{'variance'}");

my $stdev = sqrt($val);
$val = $seq->stdev(data => $refdat{'mice'}->{'data'}, prob => .5);
ok(equal($val, $stdev), "joincount stdev observed  $val != $stdev");

my $obsdev = $refdat{'mice'}->{'observed'} - $refdat{'mice'}->{'expected'}; 
$val = $seq->obsdev(data => $refdat{'mice'}->{'data'}, prob => .5);
ok(equal($val, $obsdev), "joincount obsdev observed  $val != $obsdev");

$val = $seq->z_value(data => $refdat{'mice'}->{'data'}, prob => .5);
ok(equal($val, $refdat{'mice'}->{'z_value'}), "z_value  observed  $val != $refdat{'mice'}->{'z_value'}");

# Using raw data already loaded:
eval { $seq->load(@{$refdat{'chimps'}->{'data'}});};
ok(!$@, do {chomp $@; "Data load failed: $@";});
$val = $seq->observed();
ok(equal($val, $refdat{'chimps'}->{'observed'}), "observed  observed  $val != $refdat{'chimps'}->{'observed'}");

$val = $seq->expected();
ok(equal($val, $refdat{'chimps'}->{'expected'}), "expected  observed  $val != $refdat{'chimps'}->{'expected'}");

$val = $seq->variance();
ok(equal($val, $refdat{'chimps'}->{'variance'}), "variance  observed  $val != $refdat{'chimps'}->{'variance'}");

# Using transformed (matched) data - direct calls to descriptives
eval {$seq->load(data => [1, 0, 1, 0, 1, 0, 0, 0]);};
ok(!$@, do {chomp $@; "Data load failed: $@";});

$val = $seq->observed();
ok(equal($val, $refdat{'matched'}->{'observed'}), "observed  observed  $val != $refdat{'matched'}->{'observed'}");

$val = $seq->expected();
ok(equal($val, $refdat{'matched'}->{'expected'}), "expected  observed  $val != $refdat{'matched'}->{'expected'}");

$val = $seq->variance();
ok(equal($val, $refdat{'matched'}->{'variance'}), "variance  observed  $val != $refdat{'matched'}->{'variance'}");

$val = $seq->z_value(prob => .5);
ok(equal($val, $refdat{'matched'}->{'z_value'}), "z_value  observed  $val != $refdat{'matched'}->{'z_value'}");

$val = $seq->z_value(data => $refdat{'matched'}->{'data'}, prob => .5);
ok(equal($val, $refdat{'matched'}->{'z_value'}), "z_value  observed  $val != $refdat{'matched'}->{'z_value'}");

$val = $seq->p_value(data => $refdat{'matched'}->{'data'}, prob => .5);
ok(equal($val, $refdat{'matched'}->{'p_value'}), "pvalue observed  $val != $refdat{'matched'}->{'p_value'}");

sub equal {
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
