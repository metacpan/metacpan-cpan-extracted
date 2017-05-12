use Statistics::DEA;

print "1..8\n";

my $dea = Statistics::DEA->new(0.9, 10);

print "ok 1\n";

sub near {
    my ($p, $q, $r) = @_;
    abs($q ? $p / $q - 1 : $p) < (defined $r ? $r : 0.000001);
}

print "ok 2\n" if near($dea->{sum_of_weights}      , 0);
print "ok 3\n" if near($dea->{sum_of_data}         , 0);
print "ok 4\n" if near($dea->{sum_of_squared_data} , 0);
print "ok 5\n" if near($dea->{previous_time}       , -1e38);
print "ok 6\n" if near($dea->alpha                 , 0.9);
print "ok 7\n" if near($dea->max_gap               , 10);
print "ok 8\n" if near($dea->{max_weight}          , 1 - 0.9 ** 10);

