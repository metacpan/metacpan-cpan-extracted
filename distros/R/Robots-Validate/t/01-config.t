#!perl

use Test2::V0 -no_srand;

use Test::File::ShareDir -share => {
    -dist => {
        "Robots-Validate" => "share"
    }
};

use File::Temp qw( tempfile );
use Robots::Validate;

subtest 'arrayref' => sub {

    ok my $v = Robots::Validate->new(
        config => [
            {
                name    => "02",
                agents  => [ "example-1" ],
                domain  => ".example.com",
                network => ['192.160.0.0/24'],
            },
            {
                name    => "01",
                agents  => [ "example-2" ],
                domain  => ".example.org",
                network => ['192.160.1.0/24'],
            },
        ]
    );

    is $v->config,
      [
        {
            name    => "02",
            agents  => [ "example-1" ],
            domain  => ".example.com",
            network => ['192.160.0.0/24'],
        },
        {
            name    => "01",
            agents  => [ "example-2" ],
            domain  => ".example.org",
            network => ['192.160.1.0/24'],
        },
      ],
      'expected config (order unchanged)';

};

subtest 'hashref' => sub {

    ok my $v = Robots::Validate->new(
        config => {
            '02' => {
                agents  => "example-1",
                domain  => ".example.com",
                network => ['192.160.0.0/24'],
            },
            '01' => {
                agents  => "example-2",
                domain  => ".example.org",
                network => ['192.160.1.0/24'],
            },
        }
    );

    is $v->config,
      [
        {
            name    => "01",
            agents  => [ "example-2" ],
            domain  => ".example.org",
            network => ['192.160.1.0/24'],
        },
        {
            name    => "02",
            agents  => [ "example-1" ],
            domain  => ".example.com",
            network => ['192.160.0.0/24'],
        },
      ],
      'expected config (sorted by keys)';

};

subtest 'file' => sub {

    my ($fh, $filename) = tempfile();

    say {$fh} << 'CONFIG';
[02]
name    = "second"
agents  = "example-1"
domain  = ".example.com"
network = [ "192.160.0.0/24" ]

[01]
name    = "first"
agents  = "example-2"
domain  = ".example.org"
network = [ "192.160.1.0/24" ]

CONFIG

    close $fh;

    ok my $v = Robots::Validate->new( config => $filename );

    is $v->config,
      [
        {
            name    => "first",
            agents  => [ "example-2" ],
            domain  => ".example.org",
            network => ['192.160.1.0/24'],
        },
        {
            name    => "second",
            agents  => [ "example-1" ],
            domain  => ".example.com",
            network => ['192.160.0.0/24'],
        },
      ],
      'expected config (sorted by keys)';

};

subtest 'default' => sub {

    ok my $v = Robots::Validate->new();

    ok $v->config, "has config";
};

done_testing;
