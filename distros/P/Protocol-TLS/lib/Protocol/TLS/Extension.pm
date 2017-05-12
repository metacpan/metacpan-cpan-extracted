package Protocol::TLS::Extension;
use strict;
use warnings;
use Carp;
use Module::Runtime qw(require_module);
use Protocol::TLS::Trace qw(tracer);

sub ext_decode {
    my ( $ctx, $result_ref, $buf_ref, $buf_offset, $length ) = @_;

    # Length error
    if ( $length < 2 ) {
        tracer->debug("Extensions length error: MUST be at least 2 bytes\n");
        $ctx->error();
        return undef;
    }

    my $ext_l = unpack 'n', substr $$buf_ref, $buf_offset, 2;
    my $offset = 2;

    # Length error
    if ( $offset + $ext_l > $length ) {
        tracer->debug("Extensions length error: $ext_l\n");
        $ctx->error();
        return undef;
    }

    while ( $offset + 4 < $length ) {
        my ( $type, $l ) = unpack 'n2', substr $$buf_ref,
          $buf_offset + $offset, 4;
        $offset += 4;

        if ( $offset + $l > $length ) {
            tracer->debug("Extension $type length error: $l\n");
            $ctx->error();
            return undef;
        }

        if ( exists $ctx->{extensions}->{$type} ) {
            $ctx->{extensions}->{$type}->decode( $ctx, \$$result_ref->{$type},
                $buf_ref, $buf_offset + $offset, $l );
        }
        $offset += $l;
    }

    return $offset;
}

sub ext_encode {
    croak "not implemented";
}

sub load_extensions {
    my $ctx = shift;
    for my $ext (@_) {
        my $m = 'Protocol::TLS::Extension::' . $ext;
        require_module($m);
        $ctx->{extensions}->{ $m->type } = $m->new;
    }
}

1
