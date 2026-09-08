#!perl

use Devel::Hide qw( Aho::Corasick::XS );

use Test2::V0;
use Test2::Tools::Exception qw( dies );

use Test::File::ShareDir -share => {
    -dist => {
        "Robots-Validate" => "share"
    }
};

use Net::DNS::Resolver::Mock;

use Robots::Validate;

subtest 'sanity checks' => sub {
    like dies { require "Aho::Corasick::XS" }, qr/\ACan't locate Aho::Corasick::XS/;
};

my $res = Net::DNS::Resolver::Mock->new;
$res->zonefile_parse(
    <<ZONE
node-1.crawl.example.local 3600 A 192.168.1.1
1.1.168.192.in-addr.arpa. 3600 IN PTR node-1.crawl.example.local.
ZONE
);

subtest 'domain as regexp' => sub {

    my @robots = (
        {
            name    => 'bogus',
            agents  => [qw( bogobot )],
            network => [ '10.10.10.0/24' ],
        },
        {
            name    => 'example',
            agents  => [qw( examplebot hoohabot )],
            domain  => '/\.crawl\.example\.local$/',
            network => [ '192.168.1.1' ],
        },
    );

    isa_ok my $rv = Robots::Validate->new(
        resolver     => $res,
        config       => \@robots,
        validation_mode => 'relaxed',
      ),
      'Robots::Validate';

    ok $rv->_agents, "instantiate the internal configuration";

    is $rv->_match_ip('192.168.1.1') => 'example', '_match_ip';
    is $rv->validate('192.168.1.1')  => [ "example", undef ], "validate IP with no UA string";

    is
      $rv->validate( '192.168.1.1', 'Morkzilla/5.0 examplebot/1.0' ),
      [ "example" => "examplebot" ],
      'validate with UA string';

    is
      $rv->validate( '192.168.1.1', 'hoohabot/2.0' ),
      [ "example" => "hoohabot" ],
      'validate with UA string';

    ok $rv->validate( '192.168.1.1', { agent => 'Morkzilla/5.0 bogobot examplebot/1.0' } ), 'validate with args';

    ok $rv->validate(
        {
            REMOTE_ADDR     => '192.168.1.1',
            HTTP_USER_AGENT => 'Morkzilla/5.0 examplebot/1.0',
        }
      ),
      'validate with UA string';

    ok $rv->bad_robot(
        {
            REMOTE_ADDR     => '192.168.2.3',
            HTTP_USER_AGENT => 'Morkzilla/5.0 examplebot/1.0',
        }
      ),
      'bad_robot';

    ok !$rv->validate('192.168.1.2'), 'failed validation';

    is $rv->validate( '192.168.2.3', 'Morkzilla/5.0 examplebot/1.0' ), "", 'failed validation';

    ok $rv->bad_robot( '192.168.2.3', 'Morkzilla/5.0 examplebot/1.0' ), 'bad_robot';

    is $rv->validate( '192.168.7.6', 'Morkzilla/5.0 Chromezilla/1.2.3' ), undef, 'unknown UA';

};

subtest 'domain as array of strings' => sub {

    my @robots = (
        {
            name   => 'example',
            agents => [qw( examplebot hoohabot )],
            domain => [qw( .crawl.example.local )],
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

    is
      $rv->validate( '192.168.1.1', 'hoohabot/2.0' ),
      [ "example" => "hoohabot" ],
      'validate with UA string';

    ok $rv->validate( '192.168.1.1', { agent => 'Morkzilla/5.0 examplebot/1.0' } ), 'validate with args';

    ok $rv->validate(
        {
            REMOTE_ADDR     => '192.168.1.1',
            HTTP_USER_AGENT => 'Morkzilla/5.0 examplebot/1.0',
        }
      ),
      'validate with UA string';

    ok !$rv->validate('192.168.1.2'), 'failed validation';

    ok !$rv->validate( '192.168.2.3', 'Morkzilla/5.0 examplebot/1.0' ), 'failed validation';

    ok !$rv->validate( '192.168.1.1', { agent => 'Googlebot' } ), 'failed validtion with UA';

};

done_testing;
