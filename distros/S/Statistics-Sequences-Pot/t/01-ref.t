use strict;
use warnings;
use Test::More tests => 11;
use constant EPS => 1e-2;

BEGIN { use_ok('Statistics::Sequences::Pot') };

my $seq = Statistics::Sequences::Pot->new();
isa_ok($seq, 'Statistics::Sequences::Pot');

my %refdat = ( observed => 35.111, expected => 29.287, variance => 11.38602, z_value => 1.577, p_value => .11463, data => [qw/5 5 5 1 4 4 10 5 4 11 4 6 6 6 7 6 3 4 3 5 3 1 4 5 8 5 8 3 3 7 4 5 5 4 2 2 5 3 6 4 5 2 4 4 5 6 5 8 4 6 11 5 3 7 7 8 4 4 4 4 2 8 9 5 5 6 3 4 2 4 5 4 5 5 5 7 4 9 1 4 2 4 7 4 6 6 7 7 4 4 8 6 7 2 5 7 7 1 3 3 4 5 6 3 5 9 2 3 1 3 3 6 3 3 6 5 6 3 6 6 5 4 3 5 5 6 5 3 4 4 3 4 8 8 5 7 9 4 8 6 7 4 7 5 5 7 7 8 5 7 3 7 5 5 1 4 3 3 6 3 4 9 3 2 9 3 9 7 5 3 2 8 6 5 7 4 6 6 3 6 6 5 9 5 2 6 7 2 8 8 2 4 5 4 8 5 2 5 4 6 6 9 3 4 9 7 6 2 7 7 4 3 7 3 2 6 4 5 6 3 7 5 7 6 6 6 5 4 6 5 6 7 1 2 3 5 6 3 9 5 7 6 3 8 9 7 4 5 7 6 5 4 4 7 8 9 6 3 5 1 8 6 6 3 4 3 6 6 3 6 2 3 7 6 3 5 6 3 5 5/]);

my $val;
$seq->load($refdat{'data'});
$val = $seq->observed(state => 7);
ok(equal($val, $refdat{'observed'}), "pot observed  $val != $refdat{'observed'}");

$val = $seq->expected(state => 7);
ok(equal($val, $refdat{'expected'}), "pot expected  $val != $refdat{'expected'}");

$val = $seq->variance(state => 7);
ok(equal($val, $refdat{'variance'}), "pot variance  $val != $refdat{'variance'}");

my $stdev = sqrt($val);
$val = $seq->stdev(state => 7);
ok(equal($val, $stdev), "pot stdev $val != $stdev");

$val = $seq->obsdev(state => 7);
my $obsdev = $refdat{'observed'} - $refdat{'expected'};
ok(equal($val, $obsdev), "pot obsdev $val != $obsdev");

$val = $seq->zscore(state => 7);
ok(equal($val, $refdat{'z_value'}), "pot zscore  $val != $refdat{'z_value'}");

$val = $seq->p_value(state => 7);
ok(equal($val, $refdat{'p_value'}), "pot p_value  $val != $refdat{'p_value'}");

eval {$seq->unload();};
ok(!$@, "Unload failed");

$val = $seq->p_value(data => $refdat{'data'}, state => 7);
ok(equal($val, $refdat{'p_value'}), "pot p_value $val != $refdat{'p_value'}");

sub equal {
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
