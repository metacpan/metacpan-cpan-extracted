#!perl
use Test2::V0 -no_srand;
use Net::DNS::Resolver::Mock;
use Net::IP qw( ip_expand_address );
use Robots::Validate;

# Net::DNS::Resolver::Mock converts an IPv4 literal to in-addr.arpa but NOT an
# IPv6 literal to ip6.arpa, so the reverse names are spelled out here.
sub arpa6 {
    ( my $n = ip_expand_address( shift, 6 ) ) =~ s/://g;
    return join( '.', reverse split //, $n ) . '.ip6.arpa.';
}

my $res = Net::DNS::Resolver::Mock->new;
$res->zonefile_parse( <<ZONE );
node4.crawl.example.local. 3600 IN A    203.0.113.7
7.113.0.203.in-addr.arpa.  3600 IN PTR  node4.crawl.example.local.
node6.crawl.example.local. 3600 IN AAAA 2001:db8::7
@{[ arpa6('2001:db8::7') ]}    3600 IN PTR  node6.crawl.example.local.
liar.crawl.example.local.  3600 IN AAAA 2001:db8::1234
@{[ arpa6('2001:db8::99') ]}   3600 IN PTR  liar.crawl.example.local.
@{[ arpa6('2001:db8::1234') ]} 3600 IN PTR  liar.crawl.example.local.
ZONE

my $rv = Robots::Validate->new(
    resolver => $res,
    config   => [ { name => 'example', agents => ['examplebot'],
                    domain => '.crawl.example.local' } ],
);
my $UA = 'examplebot/1.0';

is $rv->validate( '203.0.113.7', $UA ), [ example => 'examplebot' ],
   'IPv4 robot still validates (regression guard)';

is $rv->validate( '::ffff:203.0.113.7', $UA ), [ example => 'examplebot' ],
   'IPv4 robot behind a dual-stack listener (v4-mapped REMOTE_ADDR) validates';

is $rv->validate( '2001:db8::7', $UA ), [ example => 'examplebot' ],
   'IPv6 robot validates -- compressed REMOTE_ADDR form';

is $rv->validate( '2001:0db8:0000:0000:0000:0000:0000:0007', $UA ),
   [ example => 'examplebot' ], 'IPv6 robot validates -- expanded form';

is $rv->validate( '2001:DB8::7', $UA ), [ example => 'examplebot' ],
   'IPv6 robot validates -- uppercase form';

# The discriminating pair: same PTR name, two addresses. Only the one the
# forward record actually names may pass.
is $rv->validate( '2001:db8::1234', $UA ), [ example => 'examplebot' ],
   'the address the forward record names validates';

ok !$rv->validate( '2001:db8::99', $UA ),
   'an address whose PTR names that host but whose forward record points '
 . 'elsewhere is rejected -- the forward check firing, not a dead path';

ok !$rv->validate( '2001:db8::abcd', $UA ),
   'IPv6 address with no PTR at all is rejected';

ok !$rv->validate( 'not-an-ip', $UA ), 'unparseable address fails closed';

done_testing;
