use strict;
use warnings;

use Test::More;
use Test::NoWarnings;
use Test::Deep;
use Test::Exception;

use constant EXT_CLASS => 'Net::WebSocket::Handshake::Extension';

plan tests => 1 + 15;

use Net::WebSocket::PMCE::deflate::Server ();

my $max_window_bits = ( Net::WebSocket::PMCE::deflate::Server->VALID_MAX_WINDOW_BITS() )[-1];
my $min_window_bits = ( Net::WebSocket::PMCE::deflate::Server->VALID_MAX_WINDOW_BITS() )[0];

my $default = Net::WebSocket::PMCE::deflate::Server->new();

is(
    $default->deflate_max_window_bits(),
    ( Net::WebSocket::PMCE::deflate->VALID_MAX_WINDOW_BITS() )[-1],
    'deflate_max_window_bits() default',
);

is(
    $default->inflate_max_window_bits(),
    ( Net::WebSocket::PMCE::deflate->VALID_MAX_WINDOW_BITS() )[-1],
    'inflate_max_window_bits() default',
);

ok(
    !$default->deflate_no_context_takeover(),
    'deflate_no_context_takeover() default = off',
);

ok(
    !$default->inflate_no_context_takeover(),
    'inflate_no_context_takeover() default = off',
);

#----------------------------------------------------------------------

my $pmd = Net::WebSocket::PMCE::deflate::Server->new();

$pmd->consume_parameters('server_no_context_takeover' => undef );

ok(
    $pmd->deflate_no_context_takeover(),
    'deflate_no_context_takeover() after parsing extension string',
);

ok(
    !$pmd->inflate_no_context_takeover(),
    'inflate_no_context_takeover() default = off',
);

lives_ok(
    sub {
        $pmd->consume_parameters(
            client_no_context_takeover => undef
        );
    },
    'consume_parameters() works multiply (for a server)',
);

#----------------------------------------------------------------------
#client_no_context_takeover
{
    my $pmd = Net::WebSocket::PMCE::deflate::Server->new();

    $pmd->consume_parameters('client_no_context_takeover' => undef);

    ok(
        $pmd->inflate_no_context_takeover(),
        'inflate_no_context_takeover() default = off',
    );
}

#----------------------------------------------------------------------
#server_max_window_bits
{
    throws_ok(
        sub {
            Net::WebSocket::PMCE::deflate::Server->new( deflate_max_window_bits => $max_window_bits + 1 ),
        },
        qr<deflate_max_window_bits>,
        'deflate_max_window_bits: enforce max',
    );

    throws_ok(
        sub {
            Net::WebSocket::PMCE::deflate::Server->new( deflate_max_window_bits => $min_window_bits - 1 ),
        },
        qr<deflate_max_window_bits>,
        'deflate_max_window_bits: enforce min',
    );

    my $pmd = Net::WebSocket::PMCE::deflate::Server->new( deflate_max_window_bits => 12 );

    $pmd->consume_parameters(server_max_window_bits => 11);

    is( $pmd->deflate_max_window_bits(), 11, 'absorb received server_max_window_bits' );
}

#----------------------------------------------------------------------
#client_max_window_bits
{
    throws_ok(
        sub {
            Net::WebSocket::PMCE::deflate::Server->new( inflate_max_window_bits => $max_window_bits + 1 ),
        },
        qr<inflate_max_window_bits>,
        'inflate_max_window_bits: enforce max',
    );

    throws_ok(
        sub {
            Net::WebSocket::PMCE::deflate::Server->new( inflate_max_window_bits => $min_window_bits - 1 ),
        },
        qr<inflate_max_window_bits>,
        'inflate_max_window_bits: enforce min',
    );

    my $pmd = Net::WebSocket::PMCE::deflate::Server->new( inflate_max_window_bits => 12 );

    $pmd->consume_parameters(client_max_window_bits => 11);

    is( $pmd->inflate_max_window_bits(), 11, 'absorb received client_max_window_bits' );

    $pmd = Net::WebSocket::PMCE::deflate::Server->new( inflate_max_window_bits => 12 );

    $pmd->consume_parameters(server_max_window_bits => 13);

    is( $pmd->inflate_max_window_bits(), 12, 'ignore received client_max_window_bits when greater than preset' );
}
