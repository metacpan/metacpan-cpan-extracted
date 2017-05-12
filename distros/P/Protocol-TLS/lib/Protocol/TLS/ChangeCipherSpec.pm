package Protocol::TLS::ChangeCipherSpec;
use strict;
use warnings;
use Protocol::TLS::Trace qw(tracer);
use Protocol::TLS::Constants qw(:c_types);

sub decode {
    my ( $ctx, $buf_ref, $buf_offset, $length ) = @_;
    return 0 if length($$buf_ref) - $buf_offset < 1;
    my ($type) = unpack "x${buf_offset}C", $$buf_ref;
    return undef unless $type == 1 && $length == 1;

    $ctx->state_machine( 'recv', CTYPE_CHANGE_CIPHER_SPEC, 1 );
    1;
}

sub encode {
    chr 1;
}

1
