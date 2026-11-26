#!perl

use Test2::V0 -no_srand;

use Test::File::ShareDir -share => {
    -dist => {
        "Robots-Validate" => "share"
    }
};

use List::Util qw( shuffle );
use Net::DNS::Resolver::Mock;

use Robots::Validate;

my $res = Net::DNS::Resolver::Mock->new;
$res->zonefile_parse(
    <<ZONE
node-1.crawl.example-1.local 3600 A 192.168.1.1
node-1.crawl.example-2.local 3600 A 192.168.2.1
1.1.168.192.in-addr.arpa. 3600 IN PTR node-1.crawl.example-1.local.
1.2.168.192.in-addr.arpa. 3600 IN PTR node-1.crawl.example-2.local.
ZONE
);

subtest 'multiple domains' => sub {

    my @robots = (
        {
            name   => 'example',
            agents => [ qw( examplebot ) ],
            domain => [ shuffle qw( .example-1.local .example-2.local ) ],
        },
    );

    isa_ok my $rv = Robots::Validate->new(
        resolver     => $res,
        config       => \@robots,
        die_on_error => 0,
      ),
      'Robots::Validate';

    is
      $rv->validate( '192.168.1.1', 'Morkzilla/5.0 examplebot/1.0' ),
      [ "example" => "examplebot" ],
      'validate with UA string';

    ok $rv->validate( '192.168.1.1', { agent => 'Morkzilla/5.0 examplebot/1.0' } ), 'validate example-1.local';

    ok $rv->validate( '192.168.2.1', { agent => 'Morkzilla/5.0 examplebot/2.0' } ), 'validate example-2.local';

};

done_testing;
