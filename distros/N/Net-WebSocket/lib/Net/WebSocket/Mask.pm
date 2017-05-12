package Net::WebSocket::Mask;

use strict;
use warnings;

use Module::Load ();

my $_loaded_rng;

sub create {
    return pack 'L', ( ( (rand 65536) << 16 ) | (rand 65536) );
}

sub apply {
    my ($payload_sr, $mask) = @_;

    $mask = $mask x (int(length($$payload_sr) / 4) + 1);

    substr($mask, length($$payload_sr)) = q<>;

    $$payload_sr .= q<>;
    $$payload_sr ^= $mask;

    return;
}

1;
