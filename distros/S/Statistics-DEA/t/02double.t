use Statistics::DEA;

print "1..11\n";

my $eps  = 1e-6;
my $dea  = Statistics::DEA->new(1 - $eps, 1);
my $time = 0;

$dea->update(2, $time++);
$dea->update(6, $time++);

print "ok 1\n";

sub near {
    my ($p, $q, $r) = @_;
    abs($q ? $p / $q - 1 : $p) < (defined $r ? $r : 0.000001);
}

print "ok 2\n" if near($dea->{sum_of_weights}      , 1.99999900005751e-06);
print "ok 3\n" if near($dea->{sum_of_data}         , 7.99999800023004e-06);
print "ok 4\n" if near($dea->{sum_of_squared_data} , 3.99999960011502e-05);
print "ok 5\n" if near($dea->{previous_time}       , 1);
print "ok 6\n" if near($dea->alpha                 , 1 - $eps);
print "ok 7\n" if near($dea->max_gap               , 1);
print "ok 8\n" if near($dea->{max_weight}          , 1.00000000002876e-06);

print "ok 9\n"  if near($dea->average()            , 4);
print "ok 10\n" if near($dea->standard_deviation() , 2);
print "ok 11\n" if near($dea->completeness($time)  , 1.99999700005851e-06);


