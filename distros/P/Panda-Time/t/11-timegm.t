use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use PDTest;

foreach my $file (map {"utc$_"} 1,2,3,4,5,6,7) {
    my $list = get_dates($file)->{UTC};
    foreach my $row (@$list) {
        my @params = get_row_tl($row);
        my $result = &timegm(@params);
        is($result, $row->[0], "timegm: @params");
    }
}

# check normalization

# read only values failure
ok(!eval{timegmn(0,0,0,0,0,0);1;});

my ($Y,$M,$D,$h,$m,$s);

($Y,$M,$D,$h,$m,$s) = (1970,0,1,0,0,-1);
is(&timegm($s,$m,$h,$D,$M,$Y), -1);
cmp_deeply([$Y,$M,$D,$h,$m,$s], [1970,0,1,0,0,-1]);
is(timegmn($s,$m,$h,$D,$M,$Y), -1);
cmp_deeply([$Y,$M,$D,$h,$m,$s], [1969,11,31,23,59,59]);

($Y,$M,$D,$h,$m,$s) = (1970,234,-4643,2341,-34332,-1213213);
is(timegmn($s,$m,$h,$D,$M,$Y), 219167267);
cmp_deeply([$Y,$M,$D,$h,$m,$s], [1976,11,11,15,47,47]);

($Y,$M,$D,$h,$m,$s) = (2010,-123,-1234,12345,-123456,-1234567);
is(timegmn($s,$m,$h,$D,$M,$Y), 867832073);
cmp_deeply([$Y,$M,$D,$h,$m,$s], [1997,6,2,8,27,53]);

($Y,$M,$D,$h,$m,$s) = (2010,-1,0,0,0,0);
is(timegmn($s,$m,$h,$D,$M,$Y), 1259539200);
cmp_deeply([$Y,$M,$D,$h,$m,$s], [2009,10,30,0,0,0]);

done_testing();