use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use PDTest;

foreach my $file (map {"right$_"} 1..5) {
    my $data = get_dates($file);
    while (my ($zone, $list) = each %$data) {
        tzset($zone);
        foreach my $row (@$list) {
            my @params = get_row_tl($row);
            my $result = &timelocal(@params);
            is($result, $row->[0], "timelocal($zone): @params");
            $result = join(',', &localtime($row->[0]));
            is($result, join(',', @{$row->[1]}), "localtime($zone): ".$row->[0]);
        }
    }
}

my ($Y,$M,$D,$h,$m,$s,$isdst);

# check near leap second time
tzset('right/UTC');
cmp_deeply([&localtime(1230768022)], [59, 59, 23, 31, 11, 2008, 3, 365, 0]);
cmp_deeply([&localtime(1230768023)], [60, 59, 23, 31, 11, 2008, 3, 365, 0]);
cmp_deeply([&localtime(1230768024)], [0, 0, 0, 1, 0, 2009, 4, 0, 0]);
($isdst,$Y,$M,$D,$h,$m,$s) = (1,2008,11,31,23,59,59);
is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1230768022);
is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1230768022);
cmp_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [0,2008,11,31,23,59,59]);
($isdst,$Y,$M,$D,$h,$m,$s) = (1,2008,11,31,23,59,60);
is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1230768023);
is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1230768023);
cmp_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [0,2008,11,31,23,59,60]);
($isdst,$Y,$M,$D,$h,$m,$s) = (1,2009,0,1,0,0,0);
is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1230768024);
is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1230768024);
cmp_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [0,2009,0,1,0,0,0]);

tzset('right/Europe/Moscow');
# check leap second inside transitions
cmp_deeply([&localtime(1230768021)], [58, 59, 2, 1, 0, 2009, 4, 0, 0]);
cmp_deeply([&localtime(1230768022)], [59, 59, 2, 1, 0, 2009, 4, 0, 0]);
cmp_deeply([&localtime(1230768023)], [60, 59, 2, 1, 0, 2009, 4, 0, 0]);
cmp_deeply([&localtime(1230768024)], [0, 0, 3, 1, 0, 2009, 4, 0, 0]);
cmp_deeply([&localtime(1230768025)], [1, 0, 3, 1, 0, 2009, 4, 0, 0]);
($isdst,$Y,$M,$D,$h,$m,$s) = (1,2009,0,1,2,59,58);
is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1230768021);
is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1230768021);
cmp_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [0,2009,0,1,2,59,58]);
($isdst,$Y,$M,$D,$h,$m,$s) = (1,2009,0,1,2,59,59);
is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1230768022);
is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1230768022);
cmp_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [0,2009,0,1,2,59,59]);
($isdst,$Y,$M,$D,$h,$m,$s) = (1,2009,0,1,2,59,60);
is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1230768023);
is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1230768023);
cmp_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [0,2009,0,1,2,59,60]);
($isdst,$Y,$M,$D,$h,$m,$s) = (1,2009,0,1,3,0,0);
is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1230768024);
is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1230768024);
cmp_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [0,2009,0,1,3,0,0]);
# check normalization (120 != 60+60)
($isdst,$Y,$M,$D,$h,$m,$s) = (1,2009,0,1,2,58,119);
is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1230768022);
is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1230768022);
cmp_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [0,2009,0,1,2,59,59]);
($isdst,$Y,$M,$D,$h,$m,$s) = (1,2009,0,1,2,58,120);
is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1230768024);
is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1230768024);
cmp_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [0,2009,0,1,3,0,0]);
($isdst,$Y,$M,$D,$h,$m,$s) = (1,2009,0,1,3,0,-1);
is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1230768022);
is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1230768022);
cmp_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [0,2009,0,1,2,59,59]);
($isdst,$Y,$M,$D,$h,$m,$s) = (1,2009,0,1,2,59,61);
is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1230768025);
is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1230768025);
cmp_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [0,2009,0,1,3,0,1]);

# check when last transition is leap second
cmp_deeply([&localtime(1341100822)], [58, 59, 3, 1, 6, 2012, 0, 182, 0]);
cmp_deeply([&localtime(1341100823)], [59, 59, 3, 1, 6, 2012, 0, 182, 0]);
cmp_deeply([&localtime(1341100824)], [60, 59, 3, 1, 6, 2012, 0, 182, 0]);
cmp_deeply([&localtime(1341100825)], [0, 0, 4, 1, 6, 2012, 0, 182, 0]);
cmp_deeply([&localtime(1341100826)], [1, 0, 4, 1, 6, 2012, 0, 182, 0]);
($isdst,$Y,$M,$D,$h,$m,$s) = (1,2012,6,1,3,59,58);
is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1341100822);
is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1341100822);
cmp_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [0,2012,6,1,3,59,58]);
($isdst,$Y,$M,$D,$h,$m,$s) = (1,2012,6,1,3,59,59);
is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1341100823);
is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1341100823);
cmp_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [0,2012,6,1,3,59,59]);
($isdst,$Y,$M,$D,$h,$m,$s) = (1,2012,6,1,3,59,60);
is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1341100824);
is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1341100824);
cmp_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [0,2012,6,1,3,59,60]);
($isdst,$Y,$M,$D,$h,$m,$s) = (1,2012,6,1,4,0,0);
is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1341100825);
is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1341100825);
cmp_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [0,2012,6,1,4,0,0]);
# check normalization (120 != 60+60)
($isdst,$Y,$M,$D,$h,$m,$s) = (1,2012,6,1,3,58,119);
is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1341100823);
is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1341100823);
cmp_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [0,2012,6,1,3,59,59]);
($isdst,$Y,$M,$D,$h,$m,$s) = (1,2012,6,1,3,58,120);
is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1341100825);
is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1341100825);
cmp_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [0,2012,6,1,4,0,0]);
($isdst,$Y,$M,$D,$h,$m,$s) = (1,2012,6,1,4,0,-1);
is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1341100823);
is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1341100823);
cmp_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [0,2012,6,1,3,59,59]);
($isdst,$Y,$M,$D,$h,$m,$s) = (1,2012,6,1,3,59,61);
is(timelocal($s,$m,$h,$D,$M,$Y,$isdst), 1341100826);
is(timelocaln($s,$m,$h,$D,$M,$Y,$isdst), 1341100826);
cmp_deeply([$isdst,$Y,$M,$D,$h,$m,$s], [0,2012,6,1,4,0,1]);

done_testing();