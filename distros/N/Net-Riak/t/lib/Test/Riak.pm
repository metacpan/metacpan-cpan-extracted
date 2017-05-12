package Test::Riak;
use strict;
use warnings;
use Test::More 'no_plan';
use_ok 'Net::Riak';

sub import {
    no strict 'refs';
    *{caller()."::test_riak"} = \&{"Test::Riak::test_riak"};
    *{caller()."::test_riak_pbc"} = \&{"Test::Riak::test_riak_pbc"};
    *{caller()."::test_riak_rest"} = \&{"Test::Riak::test_riak_rest"};
    *{caller()."::new_riak_client"} = \&{"Test::Riak::new_riak_client"};
    strict->import;
    warnings->import;
}

sub test_riak (&) {
    my ($test_case) = @_;
    test_riak_rest($test_case);
    test_riak_pbc($test_case);
}

sub test_riak_rest (&) {
    my ($test_case) = @_;

    if ($ENV{RIAK_REST_HOST}) {
        diag "Running for REST";
        my $client = Net::Riak->new(host => $ENV{RIAK_REST_HOST}, r => 1, w => 1, dw => 1);
        isa_ok $client, 'Net::Riak';
        is $client->is_alive, 1, 'connected';
        run_test_case($test_case, $client, 'REST');
    }
    else {
        diag "Skipping REST tests - RIAK_REST_HOST not set";
    }
}

sub test_riak_pbc (&) {
    my ($test_case) = @_;

    if ($ENV{RIAK_PBC_HOST}) {

        diag "Running for PBC";
        my ($host, $port) = split ':', $ENV{RIAK_PBC_HOST};

        my $client = Net::Riak->new(
            transport => 'PBC',
            host  => $host,
            port  => $port,
            r     => 1,
            w     => 1,
            dw    => 1,
        );

        isa_ok $client, 'Net::Riak';
        is $client->is_alive, 1, 'connected';
        run_test_case($test_case, $client, 'PBC');
    }
    else {
        diag "Skipping PBC tests - RIAK_PBC_HOST not set";
    }
}

sub new_riak_client {
    my $proto = shift;

    if ($proto eq 'PBC') {
        my ($host, $port) = split ':', $ENV{RIAK_PBC_HOST};

        return  Net::Riak->new(
            transport => 'PBC',
            host  => $host,
            port  => $port,
            r     => 1,
            w     => 1,
            dw    => 1,
        );
    }
    elsif ($proto eq 'REST') {
        return Net::Riak->new(host => $ENV{RIAK_REST_HOST});
    }

    die "Unknown protocol $proto";
}

sub run_test_case {
    my ($case, $client, $proto) = @_;

    my $bucket = "TEST_RIAK_$$".sprintf("%d", rand()*1000);

    local $@;
    eval { $case->($client, $bucket, $proto) };

    if ($@) {
        ok 0, "$@";
    }

    #TODO add bucket cleanup
}
