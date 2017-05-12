package Protocol::TLS::Compression;
use strict;
use warnings;
use Protocol::TLS::Constants qw();

sub decode {
    my ( $ctx, $buf_ref, $buf_offset, $length ) = @_;
    substr $$buf_ref, $buf_offset, $length;
}

sub encode {
    $_[1];
}

1
