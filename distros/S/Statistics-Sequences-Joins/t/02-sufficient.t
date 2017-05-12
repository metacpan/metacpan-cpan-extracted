use strict;
use warnings;
use Test::More tests => 8;
use constant EPS => 1e-2;

use Statistics::Sequences::Joins 0.20;

my $seq = Statistics::Sequences::Joins->new();
isa_ok($seq, 'Statistics::Sequences::Joins');

my %refdat = (
    esp60 => { # from ESP-60 App. 8 p 381 - without ncorr
        observed => 70, expected => 99.5, variance => 50, stdev => 7.07107, z_value => (70 - 99.5)/sqrt(50), prob => 1/2, trials => 200
    },
    esp60_ncorr => { # from ESP-60 App. 8 p 381 - adpated, with ncorr
        variance => 49.75, stdev => 7.0534, z_value => (70 - 99.5)/sqrt(49.75)
    },
);

my $val;

# ESP-60 data (sufficient):

$val = $seq->expected(trials => $refdat{'esp60'}->{'trials'}, prob => $refdat{'esp60'}->{'prob'});
ok(equal($val, $refdat{'esp60'}->{'expected'}), "expected count  $val = $refdat{'esp60'}->{'expected'}");

$val = $seq->variance(trials => $refdat{'esp60'}->{'trials'}, prob => $refdat{'esp60'}->{'prob'}); # with default n-correction
ok(equal($val, $refdat{'esp60_ncorr'}->{'variance'}), "expected count  $val = $refdat{'esp60_ncorr'}->{'variance'}");

$val = $seq->variance(trials => $refdat{'esp60'}->{'trials'}, prob => $refdat{'esp60'}->{'prob'}, ncorr => 1);
ok(equal($val, $refdat{'esp60_ncorr'}->{'variance'}), "variance  $val = $refdat{'esp60_ncorr'}->{'variance'}");

$val = $seq->variance(trials => $refdat{'esp60'}->{'trials'}, prob => $refdat{'esp60'}->{'prob'}, ncorr => 0);
ok(equal($val, $refdat{'esp60'}->{'variance'}), "variance  $val = $refdat{'esp60'}->{'variance'}");

$val = $seq->stdev(trials => $refdat{'esp60'}->{'trials'}, prob => $refdat{'esp60'}->{'prob'}, ncorr => 0);
ok(equal($val, sqrt($refdat{'esp60'}->{'variance'})), "stdev  $val = ". sqrt($refdat{'esp60'}->{'variance'}));

$val = $seq->z_value(observed => $refdat{'esp60'}->{'observed'}, trials => $refdat{'esp60'}->{'trials'}, prob => $refdat{'esp60'}->{'prob'}, ncorr => 1, ccorr => 0);
ok(equal($val, $refdat{'esp60_ncorr'}->{'z_value'}), "z_value  $val = $refdat{'esp60_ncorr'}->{'z_value'}");

$val = $seq->z_value(observed => $refdat{'esp60'}->{'observed'}, trials => $refdat{'esp60'}->{'trials'}, prob => $refdat{'esp60'}->{'prob'}, ncorr => 0, ccorr => 0);
ok(equal($val, $refdat{'esp60'}->{'z_value'}), "z_value $val = $refdat{'esp60'}->{'z_value'}");

sub equal {
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
