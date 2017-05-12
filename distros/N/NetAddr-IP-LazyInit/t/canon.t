use Test::More;

my %cases =
(
 '127.1'           => '127.0.0.1',
 'DEAD:BEEF::1'	   => 'dead:beef::1',

 '1234:5678:90AB:CDEF:0123:4567:890A:BCDE'
    => '1234:5678:90ab:cdef:123:4567:890a:bcde',
);

my $tests = keys %cases;
plan tests => 1 + $tests;

SKIP: {
    use_ok('NetAddr::IP::LazyInit') or skip "Failed to load NetAddr::IP::LazyInit", $tests;
    skip("NetAddr::IP >= 4.071 required for canon tests", $tests) if (NetAddr::IP->VERSION < 4.071);
    for my $c (sort keys %cases)
    {
	my $ip = new NetAddr::IP::LazyInit $c;
	my $rv = $ip->canon;
	is($rv, $cases{$c}, "canon($c ) returns $rv");
    }
}
