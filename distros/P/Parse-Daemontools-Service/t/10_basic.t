use strict;
use Test::More;

use Test::Time time => 1386332379;

use Parse::Daemontools::Service;

use FindBin;

my $BASE_DIR = join '/', $FindBin::Bin, 'service';

sub test_service {
    my %specs = @_;
    my($base_dir, $service_name, $desc, $new_argv, $status_argv, $expect)
        = @specs{qw(base_dir service_name desc new_argv status_argv expect)};

    $new_argv ||= {};
    $status_argv ||= {};

    subtest $desc => sub {
        my $ds = Parse::Daemontools::Service->new($new_argv);

        my $got = $ds->status($service_name, $status_argv);

        is_deeply($got, $expect, 'status detail');
    };
}

test_service(
    service_name => 'upupup',
    desc         => 'running service',
    new_argv     => {
        base_dir => $BASE_DIR,
    },
    expect       => {
        env      => {
            BAR => "bar",
            FOO => "foo"
        },
        info     => "",
        pid      => 28247,
        seconds  => 4345,
        start_at => 1386328034,
        service  => join('/', $BASE_DIR, 'upupup'),
        status   => "up",
    },
);

test_service(
    service_name => 'downdown',
    desc         => 'not running service',
    new_argv     => {
        base_dir => $BASE_DIR,
    },
    expect       => {
        env      => {},
        info     => "normally up",
        pid      => undef,
        seconds  => 636298,
        start_at => 1385696081,
        service  => join('/', $BASE_DIR, 'downdown'),
        status   => "down",
    },
);

test_service(
    service_name => 'upupup',
    desc         => 'another envdir (scalar)',
    new_argv     => {
        base_dir => $BASE_DIR,
    },
    status_argv => {
        env_dir => join('/', $BASE_DIR, 'upupup', 'env2'),
    },
    expect       => {
        env      => {
            BAR => "bar2",
            BAZ => "baz"
        },
        info     => "",
        pid      => 28247,
        seconds  => 4345,
        start_at => 1386328034,
        service  => join('/', $BASE_DIR, 'upupup'),
        status   => "up",
    },
);

test_service(
    service_name => 'upupup',
    desc         => 'another envdir (arrayref)',
    new_argv     => {
        base_dir => $BASE_DIR,
    },
    status_argv => {
        env_dir => [ join('/', $BASE_DIR, 'upupup', 'env2') ],
    },
    expect       => {
        env      => {
            BAR => "bar2",
            BAZ => "baz"
        },
        info     => "",
        pid      => 28247,
        seconds  => 4345,
        start_at => 1386328034,
        service  => join('/', $BASE_DIR, 'upupup'),
        status   => "up",
    },
);

test_service(
    service_name => 'upupup',
    desc         => 'cascade envdir',
    new_argv     => {
        base_dir => $BASE_DIR,
    },
    status_argv => {
        env_dir => [
            join('/', $BASE_DIR, 'upupup', 'env'),
            join('/', $BASE_DIR, 'upupup', 'env2'),
        ],
    },
    expect       => {
        env      => {
            FOO => "foo",
            BAR => "bar2",
            BAZ => "baz"
        },
        info     => "",
        pid      => 28247,
        seconds  => 4345,
        start_at => 1386328034,
        service  => join('/', $BASE_DIR, 'upupup'),
        status   => "up",
    },
);

done_testing;
