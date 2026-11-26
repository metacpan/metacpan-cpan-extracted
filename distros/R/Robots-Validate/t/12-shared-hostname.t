#!perl

use Test2::V0 -no_srand;

use Test::File::ShareDir -share => {
    -dist => {
        "Robots-Validate" => "share"
    }
};

use Net::DNS::Resolver::Mock;

use Robots::Validate;

my $res = Net::DNS::Resolver::Mock->new;
$res->zonefile_parse(
    <<ZONE
crawl.example.local 3600 A 192.168.1.1
crawl.example.local 3600 A 192.168.1.2
crawl.example.local 3600 A 192.168.1.3
crawl.example.local 3600 A 192.168.1.4
1.1.168.192.in-addr.arpa. 3600 IN PTR crawl.example.local.
2.1.168.192.in-addr.arpa. 3600 IN PTR crawl.example.local.
3.1.168.192.in-addr.arpa. 3600 IN PTR crawl.example.local.
4.1.168.192.in-addr.arpa. 3600 IN PTR crawl.example.local.
ZONE
);

subtest 'same hostname for multiple ips' => sub {

    my @robots = (
        {
            name   => 'example',
            agents => [qw( examplebot )],
            domain => 'crawl.example.local',
        },
    );

    isa_ok my $rv = Robots::Validate->new(
        resolver => $res,
        config   => \@robots,
      ),
      'Robots::Validate';

    for my $i ( 1 .. 4 ) {
        is
          $rv->validate( '192.168.1.' . $i, 'Morkzilla/5.0 examplebot/1.0' ),
          [ "example" => "examplebot" ],
          'validate with UA string';
    }

};

done_testing;
