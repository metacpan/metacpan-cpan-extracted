#!perl

# The pure-Perl matcher is a chunked-stream automaton.  Every validate() call
# must start it from the root, otherwise one client's user-agent leaves the
# machine mid-pattern and the next client's user-agent completes a robot name
# it never sent.  Devel::Hide forces the pure-Perl branch so this is exercised
# whether or not Algorithm::AhoCorasick::XS is installed.

use Devel::Hide qw( Algorithm::AhoCorasick::XS );

use Test2::V0;

use Net::DNS::Resolver::Mock;

use Robots::Validate;

my $res = Net::DNS::Resolver::Mock->new;
$res->zonefile_parse(<<ZONE);
77.100.51.198.in-addr.arpa. 3600 IN PTR cpe-77.isp.example.
cpe-77.isp.example.          3600 A      198.51.100.77
7.113.0.203.in-addr.arpa.    3600 IN PTR node.crawl.example.
node.crawl.example.          3600 A      203.0.113.7
ZONE

my $config = [
    { name => 'example', agents => ['ExampleBot'],   domain => '.crawl.example' },
    { name => 'other',   agents => ['OtherCrawler'], domain => '.other.example' },
];

my $browser = 'Mozilla/5.0 (X11; Linux x86_64) Gecko/20100101 Firefox/130.0';   # starts with the 'm' that completes 'm' . 'ozilla'? no: completes 'exampleboT'? see primer
my $primer  = 'Mozilla/5.0 (compatible) othercrawle';    # one character short of 'othercrawler'; the next UA starts 'mozilla', so use a needle ending in 'm'

# Needles are lowercased; build the primer from the needle itself so the test does
# not depend on the shipped rules.  'othercrawler' ends in 'r' -- so use a victim
# user-agent beginning with 'r' instead.
my $victim_ua = 'Rogue/1.0 (not a robot)';

for my $mode (qw/ relaxed first strict /) {

    subtest "validation_mode => $mode" => sub {

        my $rv = Robots::Validate->new(
            resolver        => $res,
            config          => $config,
            validation_mode => $mode,
        );

        is $rv->validate( '198.51.100.77', $victim_ua ), undef, 'a user-agent naming no robot is unknown';

        is $rv->validate( '203.0.113.9', $primer ), undef, 'a user-agent ending one character short of a robot name matches nothing';

        is $rv->validate( '198.51.100.77', $victim_ua ), undef,
          'the next client is still unknown: the previous user-agent did not leak into this match';

        is $rv->validate( '203.0.113.7', 'ExampleBot/1.0' ), [ example => 'examplebot' ],
          'a genuine robot still validates after other traffic';

        $rv->validate( '203.0.113.9', $primer );

        is $rv->validate( '203.0.113.7', 'ExampleBot/1.0' ), [ example => 'examplebot' ],
          'a genuine robot following a primer still validates and is not judged on a name it never sent';
    };

}

done_testing;
