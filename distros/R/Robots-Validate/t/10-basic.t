#!perl

use Test::Most;
use Net::DNS::Resolver::Mock;

use_ok('Robots::Validate');

my $res = Net::DNS::Resolver::Mock->new;
$res->zonefile_parse(
    <<ZONE
node-1.crawl.example.local 3600 A 192.168.1.1
1.1.168.192.in-addr.arpa. 3600 IN PTR node-1.crawl.example.local.
ZONE
);

my @robots = (
    {
        name   => 'example',
        agent  => qr/\bexamplebot\b/,
        domain => qr/\.crawl\.example\.local$/,
    },
);

isa_ok my $rv = Robots::Validate->new(
    resolver     => $res,
    robots       => \@robots,
    die_on_error => 0,
  ),
  'Robots::Validate';

{
    ok my $answer = $rv->validate('192.168.1.1'), 'validate only IP';

    is_deeply $answer,
      {
        %{ $robots[0] },
        hostname   => 'node-1.crawl.example.local',
        ip_address => '192.168.1.1',
      },
      'answer';

}

ok $rv->validate(
    '192.168.1.1', { agent => 'Morkzilla/5.0 examplebot/1.0' }
    ),
    'validate with UA string';

ok $rv->validate(
    {
        REMOTE_ADDR     => '192.168.1.1',
        HTTP_USER_AGENT => 'Morkzilla/5.0 examplebot/1.0',
    }),
    'validate with UA string';

ok !$rv->validate('192.168.1.2'), 'failed validtion';

ok !$rv->validate('192.168.1.1', { agent => 'Googlebot' } ), 'failed validtion with UA';

done_testing;
