use Test::More tests => 10;
use Net::Proxy;

my $proxy = Net::Proxy->new(
    {   in  => { type => 'dummy' },
        out => { type => 'dummy' }
    }
);

is( $proxy->stat_opened(), 0, "No opened connection" );
is( $proxy->stat_closed(), 0, "No closed connection" );

$proxy->stat_inc_opened();
is( $proxy->stat_opened(), 1, "1 opened connection" );
$proxy->stat_inc_opened();
$proxy->stat_inc_opened();
is( $proxy->stat_opened(), 3, "3 opened connections" );

$proxy->stat_inc_closed();
is( $proxy->stat_closed(), 1, "1 closed connection" );
$proxy->stat_inc_closed();
$proxy->stat_inc_closed();
is( $proxy->stat_opened(), 3, "3 closed connections" );

my $proxy2 = Net::Proxy->new(
    {   in  => { type => 'dummy' },
        out => { type => 'dummy' }
    }
);

$proxy2->stat_inc_opened();
is( $proxy2->stat_opened(), 1, "1 opened connection");
is( Net::Proxy->stat_total_opened(), 4, "Total 4 opened connections" );

$proxy2->stat_inc_closed();
is( $proxy2->stat_closed(), 1, "1 closed connection");
is( Net::Proxy->stat_total_closed(), 4, "Total 4 closed connections" );

