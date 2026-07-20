use v5.40;
use feature 'class', 'try';
no warnings 'experimental::class', 'experimental::try';
class Net::BitTorrent::Protocol::BEP10 v2.0.0 : isa(Net::BitTorrent::Protocol::BEP52) {
    use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode bdecode];
    field $local_extensions  : param : reader = {};
    field $remote_extensions : reader = {};
    field $remote_version    : reader = undef;
    field $remote_ip         : reader = undef;
    field $metadata_size     : param : reader = 0;
    field $remote_extensions_received : reader = 0;

    # Message ID for extended messages
    use constant EXTENDED => 20;

    method send_ext_handshake () {
        my $data = { m => $local_extensions, v => 'Net::BitTorrent ' . ( $Net::BitTorrent::VERSION // $Net::BitTorrent::Protocol::BEP10::VERSION ) };
        $data->{metadata_size} = $metadata_size if $metadata_size > 0;
        my $payload = bencode($data);
        $self->send_message( EXTENDED, pack( 'C a*', 0, $payload ) );
    }

    method send_ext_message ( $name, $payload ) {
        my $id = $remote_extensions->{$name};
        if ( !defined $id ) {
            $self->_emit_log( 'fatal', "Remote does not support extension: $name" );
            return;
        }
        $self->send_message( EXTENDED, pack( 'C a*', $id, $payload ) );
    }

    method _handle_message ( $id, $payload ) {
        if ( $id == EXTENDED ) {
            return if length($payload) < 1;
            my $ext_id = unpack( 'C', substr( $payload, 0, 1, '' ) );
            if ( $ext_id == 0 ) {
                $self->_handle_ext_handshake($payload);
            }
            else {
                my $name = $self->_lookup_local_extension($ext_id);
                if ($name) {
                    $self->_emit( extended_message => $name, $payload );
                }
                else {
                    $self->_emit_log( 'debug', "Received unknown extended message ID: $ext_id" ) if $self->debug;
                }
            }
        }
        else {
            $self->SUPER::_handle_message( $id, $payload );
        }
    }

    method _handle_ext_handshake ($payload) {
        my $data;
        try {
            my @res = bdecode( $payload, 1 );
            if ( @res > 2 ) {    # Dictionary returned as key-value list + leftover
                pop @res;        # Discard leftover
                $data = {@res};
            }
            else {
                $data = $res[0];
            }
        }
        catch ($e) {
            $self->_emit_log( 'error', "Malformed extended handshake: $e" );
            return;
        }
        if ( ref $data ne 'HASH' ) {
            $self->_emit_log( 'error', 'Malformed extended handshake: data is not a hash' );
            return;
        }
        $remote_extensions = $data->{m} || {};
        if ( keys %$remote_extensions > 50 ) {
            $self->_emit_log( 'warn', "Peer claimed too many extensions: " . scalar( keys %$remote_extensions ) );
            my @keys = keys %$remote_extensions;
            $remote_extensions = { map { $keys[$_] => $remote_extensions->{ $keys[$_] } } 0 .. 49 };
        }
        if ( $self->debug ) {
            $self->_emit_log( 'debug', "Remote extensions: " . join( ", ", map {"$_=$remote_extensions->{$_}"} keys %$remote_extensions ) );
        }
        $remote_version = $data->{v}      if exists $data->{v};
        $remote_ip      = $data->{yourip} if exists $data->{yourip};
        if ( exists $data->{metadata_size} ) {
            my $ms = $data->{metadata_size};
            if ( ref $ms || !defined $ms || $ms !~ /^\d+$/ || $ms > 10 * 1024 * 1024 ) {
                $self->_emit_log( 'warn', "Peer claimed unreasonable metadata_size: $ms" );
            }
            else {
                $metadata_size = $ms;
            }
        }
        $remote_extensions_received = 1;
        $self->_emit( ext_handshake => $data );
    }

    method _lookup_local_extension ($id) {
        for my $name ( keys %$local_extensions ) {
            return $name if $local_extensions->{$name} == $id;
        }
        return undef;
    }

    method _lookup_remote_extension ($id) {
        for my $name ( keys %$remote_extensions ) {
            return $name if $remote_extensions->{$name} == $id;
        }
        return undef;
    }
} 1;
