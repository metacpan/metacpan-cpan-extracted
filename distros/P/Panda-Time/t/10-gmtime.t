use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use PDTest;

foreach my $file (map {"utc$_"} 1,2,3,4,5,6,7) {
    my $list = get_dates($file)->{UTC};
    foreach my $row (@$list) {
        my $result = join(',', &gmtime($row->[0]));
        is($result, join(',', @{$row->[1]}), 'gmtime: '.$row->[0]);
    }
}

# check scalar context
like(scalar &gmtime(1387727619), qr/^\S+ \S+ 22 15:53:39 2013$/);

done_testing();
