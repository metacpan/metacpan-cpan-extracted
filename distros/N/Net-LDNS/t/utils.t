use Test::More;

BEGIN { use_ok( 'Net::LDNS' ) }

my $res = new_ok( 'Net::LDNS', ['8.8.4.4'] );

my @addrs = sort $res->name2addr( 'b.ns.se' );
my $count = $res->name2addr( 'b.ns.se' );

is_deeply( \@addrs, [ "192.36.133.107", "2001:67c:254c:301::53" ], 'expected addresses' );
is( $count, 2, 'expected count' );

my @names = sort $res->addr2name( '8.8.8.8' );
$count = $res->addr2name( '8.8.8.8' );
is_deeply( [map {lc($_)} @names], ['google-public-dns-a.google.com.'], 'expected names' );
is( $count, 1, 'expected name count' );

done_testing;
