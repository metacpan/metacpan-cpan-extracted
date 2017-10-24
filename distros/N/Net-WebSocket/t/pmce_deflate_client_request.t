use strict;
use warnings;

use Test::More;
use Test::NoWarnings;

plan tests => 1 + 4;

use Net::WebSocket::PMCE::deflate::Client ();

my $default = Net::WebSocket::PMCE::deflate::Client->new();

is_deeply(
    [ $default->get_handshake_object()->parameters() ],
    [
        'client_max_window_bits' => undef,
    ],
    'default state',
);

sub _get_request_hash {
    my (@params) = @_;

    my $obj = Net::WebSocket::PMCE::deflate::Client->new(@params);
    my @request = $obj->get_handshake_object()->parameters();

    return { @request };
}

#----------------------------------------------------------------------

my $peer_nct = _get_request_hash( inflate_no_context_takeover => 1 );

is_deeply(
    $peer_nct,
    {
        'client_max_window_bits' => undef,
        'server_no_context_takeover' => undef,
    },
    'request no_context_takeover',
) or diag explain $peer_nct;

#----------------------------------------------------------------------

my $peer_nct_max_bits = _get_request_hash(
    inflate_no_context_takeover => 1,
    inflate_max_window_bits => 10,
);

is_deeply(
    $peer_nct_max_bits,
    {
        'client_max_window_bits' => undef,
        'server_max_window_bits' => 10,
        'server_no_context_takeover' => undef,
    },
    'request no_context_takeover and max_window_bits',
) or diag explain $peer_nct_max_bits;

#----------------------------------------------------------------------

my $all_params = _get_request_hash(
    deflate_no_context_takeover => 1,
    inflate_no_context_takeover => 1,
    inflate_max_window_bits => 10,
    deflate_max_window_bits => 11,
);

is_deeply(
    $all_params,
    {
        'client_max_window_bits' => 11,
        'server_max_window_bits' => 10,
        'server_no_context_takeover' => undef,
        'client_no_context_takeover' => undef,
    },
    'request no_context_takeover and max_window_bits',
) or diag explain $all_params;

#----------------------------------------------------------------------

1;
