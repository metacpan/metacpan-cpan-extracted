use Statistics::DEA;

print "1..11\n";

my $dea = Statistics::DEA->new(0.9, 10);

$dea->update(2, 0);

print "ok 1\n";

sub near {
    my ($p, $q, $r) = @_;
    abs($q ? $p / $q - 1 : $p) < (defined $r ? $r : 0.000001);
}

print "ok 2\n" if near($dea->{sum_of_weights}      , 0.6513215599);
print "ok 3\n" if near($dea->{sum_of_data}         , 1.3026431198);
print "ok 4\n" if near($dea->{sum_of_squared_data} , 2.6052862396);
print "ok 5\n" if near($dea->{previous_time}       , 0);
print "ok 6\n" if near($dea->alpha                 , 0.9);
print "ok 7\n" if near($dea->max_gap               , 10);
print "ok 8\n" if near($dea->{max_weight}          , 1 - 0.9 ** 10);

print "ok 9\n"  if near($dea->average()            , 2);
print "ok 10\n" if near($dea->standard_deviation() , 0);
print "ok 11\n" if near($dea->completeness(1)      , 0.58618940391);


