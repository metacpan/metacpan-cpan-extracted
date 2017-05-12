package Protocol::TLS::Alert;
use strict;
use warnings;
use Carp;
use Protocol::TLS::Trace qw(tracer);
use Protocol::TLS::Constants qw(const_name :alert_types :alert_desc);

sub decode {
    my ( $ctx, $buf_ref, $buf_offset, $length ) = @_;
    return 0 if length($$buf_ref) - $buf_offset < 2;
    my ( $alert, $desc ) = unpack "x${buf_offset}C2", $$buf_ref;

    if ( $alert == WARNING ) {
        tracer->warning(
            "warning: " . const_name( 'alert_desc', $desc ) . "\n" );
    }
    elsif ( $alert == FATAL ) {
        if ( $desc == CLOSE_NOTIFY ) {
            $ctx->close;
        }
        else {
            tracer->error(
                "fatal: " . const_name( 'alert_desc', $desc ) . "\n" );
            $ctx->shutdown(1);
        }
    }
    else {
        tracer->error("unknown alert type: $alert\n");
        return undef;
    }
    return 2;
}

sub encode {
    my ( $ctx, $alert, $desc ) = @_;
    pack "C2", $alert, $desc;
}

1
