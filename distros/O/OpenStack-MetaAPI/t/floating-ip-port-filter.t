#!/usr/bin/env perl

use strict;
use warnings;

use OpenStack::MetaAPI ();

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::OpenStack::MetaAPI qw{:all};
use Test::OpenStack::MetaAPI::Auth qw{:all};

use JSON;

mock_lwp_useragent();

$Test::OpenStack::MetaAPI::UA_DISPLAY_OUTPUT = 1;

my $api = get_api_object(use_env => 0);

ok $api, "got one api object" or die;

{
    note "Test: add_floating_ip_to_server picks correct port on multi-homed VM";

    # A multi-homed VM has ports on two different networks.
    # The floating IP should attach to the port on the matching network,
    # not blindly to the first port returned by the API.

    my $SERVER_ID      = 'server-multi-homed-1234';
    my $WRONG_PORT_ID  = 'port-wrong-network-aaaa';
    my $RIGHT_PORT_ID  = 'port-right-network-bbbb';
    my $WRONG_NET_ID   = 'net-management-0000';
    my $RIGHT_NET_ID   = 'net-production-1111';
    my $FLOATING_IP_ID = 'fip-test-5555';

    # Mock the ports endpoint: returns two ports, wrong network first
    mock_get_request(
        "http://127.0.0.1:9696/v2.0/ports?device_id=$SERVER_ID",
        application_json(encode_json({
            ports => [
                {
                    id         => $WRONG_PORT_ID,
                    device_id  => $SERVER_ID,
                    network_id => $WRONG_NET_ID,
                    status     => 'ACTIVE',
                },
                {
                    id         => $RIGHT_PORT_ID,
                    device_id  => $SERVER_ID,
                    network_id => $RIGHT_NET_ID,
                    status     => 'ACTIVE',
                },
            ]
        })),
    );

    # Mock the PUT to floatingips — capture which port_id is sent
    my $captured_port_id;
    mock_put_request(
        "http://127.0.0.1:9696/v2.0/floatingips/$FLOATING_IP_ID",
        sub {
            my ($request) = @_;
            my $body = decode_json($request->content);
            $captured_port_id = $body->{floatingip}{port_id};
            return {
                code    => 200,
                msg     => "OK",
                content => encode_json({
                    floatingip => {
                        id      => $FLOATING_IP_ID,
                        port_id => $captured_port_id,
                    }
                }),
                headers => [['Content-Type' => 'application/json']],
            };
        },
    );

    # Call with network_id to filter for the right port
    $api->add_floating_ip_to_server(
        $FLOATING_IP_ID, $SERVER_ID, network_id => $RIGHT_NET_ID,
    );

    is $captured_port_id, $RIGHT_PORT_ID,
        "floating IP attached to the port on the specified network, not the first port";
}

{
    note "Test: add_floating_ip_to_server dies when no port matches network_id";

    my $SERVER_ID      = 'server-no-match-5678';
    my $FLOATING_IP_ID = 'fip-test-6666';

    mock_get_request(
        "http://127.0.0.1:9696/v2.0/ports?device_id=$SERVER_ID",
        application_json(encode_json({
            ports => [
                {
                    id         => 'port-only-aaaa',
                    device_id  => $SERVER_ID,
                    network_id => 'net-other-9999',
                    status     => 'ACTIVE',
                },
            ]
        })),
    );

    like(
        dies {
            $api->add_floating_ip_to_server(
                $FLOATING_IP_ID, $SERVER_ID,
                network_id => 'net-nonexistent-0000',
            );
        },
        qr/Cannot find a port.*network/i,
        "dies when no port matches the requested network_id",
    );
}

{
    note "Test: add_floating_ip_to_server without network_id falls back to first port";

    my $SERVER_ID      = 'server-single-9012';
    my $FIRST_PORT_ID  = 'port-first-cccc';
    my $FLOATING_IP_ID = 'fip-test-7777';

    mock_get_request(
        "http://127.0.0.1:9696/v2.0/ports?device_id=$SERVER_ID",
        application_json(encode_json({
            ports => [
                {
                    id         => $FIRST_PORT_ID,
                    device_id  => $SERVER_ID,
                    network_id => 'net-whatever-2222',
                    status     => 'ACTIVE',
                },
            ]
        })),
    );

    my $captured_port_id;
    mock_put_request(
        "http://127.0.0.1:9696/v2.0/floatingips/$FLOATING_IP_ID",
        sub {
            my ($request) = @_;
            my $body = decode_json($request->content);
            $captured_port_id = $body->{floatingip}{port_id};
            return {
                code    => 200,
                msg     => "OK",
                content => encode_json({
                    floatingip => {
                        id      => $FLOATING_IP_ID,
                        port_id => $captured_port_id,
                    }
                }),
                headers => [['Content-Type' => 'application/json']],
            };
        },
    );

    $api->add_floating_ip_to_server($FLOATING_IP_ID, $SERVER_ID);

    is $captured_port_id, $FIRST_PORT_ID,
        "without network_id, falls back to first port (backward compat)";
}

done_testing;
