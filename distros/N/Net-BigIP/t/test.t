#!/usr/bin/perl

use strict;
use warnings;

use English qw(-no_match_vars);
use Net::BigIP;
use IO::Socket::SSL;

use Test::More;
use Test::Exception;

plan(skip_all => 'live test, set $ENV{BIGIP_TEST_URL} to a true value to run')
    if !$ENV{BIGIP_TEST_URL};
plan(skip_all => 'live test, set $ENV{BIGIP_TEST_USERNAME} to a true value to run')
    if !$ENV{BIGIP_TEST_USERNAME};
plan(skip_all => 'live test, set $ENV{BIGIP_TEST_PASSWORD} to a true value to run')
    if !$ENV{BIGIP_TEST_PASSWORD};

plan tests => 24;

my $bigip;
lives_ok {
    $bigip = Net::BigIP->new(
        url => $ENV{BIGIP_TEST_URL},
        ssl_opts => {
            verify_hostname => 0,
            SSL_verify_mode => SSL_VERIFY_NONE
        }
    );
} 'connection succeeds';

isa_ok($bigip, 'Net::BigIP');

lives_ok {
    $bigip->create_session(
        username => $ENV{BIGIP_TEST_USERNAME},
        password => $ENV{BIGIP_TEST_PASSWORD},
    );
} 'authentication succeeds';

BAIL_OUT('unable to connect, skipping remaining tests') if $EVAL_ERROR;

ok(
    defined $bigip->{agent}->default_header('X-F5-Auth-Token'),
    'bigip handle has authentication token'
);

my $result;

# certificates

$result = $bigip->get_certificates();
my $all = $result->{items};
is(ref $all, 'ARRAY', 'full certificates list');

my $cert = $all->[0];
ok(
    defined $cert->{name} &&
    defined $cert->{issuer} &&
    defined $cert->{partition},
    "full certificate has all properties"
);

SKIP: {
    skip 'no test partition', 3 unless $ENV{BIGIP_TEST_PARTITION};

    $result = $bigip->get_certificates(
        partition  => $ENV{BIGIP_TEST_PARTITION},
        properties => 'name,issuer'
    );
    my $subset = $result->{items};
    is(ref $subset, 'ARRAY', 'partition-specific certificates list');

    $cert = $subset->[0];
    ok(
        defined $cert->{name} &&
        defined $cert->{issuer} &&
        !defined $cert->{partition},
        "restricted certificate has only requested properties"
    );

    ok(
        scalar @$subset < scalar @$all,
        'second list has fewer items'
    );
};

# virtual addresses

$result = $bigip->get_virtual_addresses();
$all = $result->{items};
is(ref $all, 'ARRAY', 'full virtual addresses list');

my $virtual_address = $all->[0];
ok(
    defined $virtual_address->{address} &&
    defined $virtual_address->{floating} &&
    defined $virtual_address->{partition},
    "full virtual address has all properties"
);

SKIP: {
    skip 'no test partition', 3 unless $ENV{BIGIP_TEST_PARTITION};

    $result = $bigip->get_virtual_addresses(
        partition  => $ENV{BIGIP_TEST_PARTITION},
        properties => 'address,floating'
    );
    my $subset = $result->{items};
    is(ref $subset, 'ARRAY', 'partition-specific virtual_addresses list');

    $virtual_address = $subset->[0];
    ok(
        defined $virtual_address->{address} &&
        defined $virtual_address->{floating} &&
        !defined $virtual_address->{partition},
        "restricted virtual address has only requested properties"
    );

    ok(
        scalar @$subset < scalar @$all,
        'second list has fewer items'
    );
};

# virtual servers

$result = $bigip->get_virtual_servers();
$all = $result->{items};
is(ref $all, 'ARRAY', 'full virtual servers list');

my $virtual_server = $all->[0];
ok(
    defined $virtual_server->{name} &&
    defined $virtual_server->{destination}&&
    defined $virtual_server->{partition},
    "virtual server has all properties"
);

SKIP: {
    skip 'no test partition', 3 unless $ENV{BIGIP_TEST_PARTITION};

    $result = $bigip->get_virtual_servers(
        partition => $ENV{BIGIP_TEST_PARTITION},
        properties => 'name,destination'
    );
    my $subset = $result->{items};
    is(ref $subset, 'ARRAY', 'partition-specific virtual_servers list');

    $virtual_server = $subset->[0];
    ok(
        defined $virtual_server->{name} &&
        defined $virtual_server->{destination} &&
        !defined $virtual_server->{partition},
        "restricted virtual server has only requested properties"
    );

    ok(
        scalar @$subset < scalar @$all,
        'second list has fewer items'
    );
}

# virtual servers

$result = $bigip->get_pools();
$all = $result->{items};
is(ref $all, 'ARRAY', 'full pools list');

my $pool = $all->[0];
ok(
    defined $pool->{name} &&
    defined $pool->{monitor} &&
    defined $pool->{partition},
    "pool has all properties"
);

SKIP: {
    skip 'no test partition', 3 unless $ENV{BIGIP_TEST_PARTITION};

    $result = $bigip->get_pools(
        partition => $ENV{BIGIP_TEST_PARTITION},
        properties => 'name,monitor'
    );
    my $subset = $result->{items};
    is(ref $subset, 'ARRAY', 'partition-specific pools list');

    $pool = $subset->[0];
    ok(
        defined $pool->{name} &&
        defined $pool->{monitor} &&
        !defined $pool->{partition},
        "restricted pool has only requested properties"
    );

    ok(
        scalar @$subset < scalar @$all,
        'second list has fewer items'
    );
}
