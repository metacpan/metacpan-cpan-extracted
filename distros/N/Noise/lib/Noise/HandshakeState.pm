use v5.42.0;
use feature 'class';
no warnings 'experimental::class';
#
class Noise::HandshakeState v0.0.2 {
    use Noise::SymmetricState;
    use Noise::Pattern;
    use Crypt::PK::X25519;
    use Crypt::PK::ECC;
    #
    my %DH_CONFIG = (
        25519 => { class => 'Crypt::PK::X25519', pub_len => 32 },
        P256  => { class => 'Crypt::PK::ECC',    pub_len => 65,  params => 'secp256r1' },
        P384  => { class => 'Crypt::PK::ECC',    pub_len => 97,  params => 'secp384r1' },
        P521  => { class => 'Crypt::PK::ECC',    pub_len => 133, params => 'secp521r1' }
    );
    #
    field $s    : reader : param //= undef;    # Local static key
    field $e    : reader : param //= undef;    # Local ephemeral key
    field $rs   : reader : param //= undef;    # Remote static public key
    field $re   : reader : param //= undef;    # Remote ephemeral public key
    field $psks : reader : param //= [];       # Array of pre-shared keys
    field $psk_idx = 0;
    field $initiator       : param;            # Boolean
    field $pattern         : param;            # Pattern name or object
    field $prologue        : param //= '';     # Optional prologue
    field $symmetric_state : reader;
    field $msg_idx = 0;
    field $dh_name;
    field $dh_len;
    #
    ADJUST {
        my $full_name = $pattern;
        if ( $full_name !~ /^Noise(?:PSK)?_/ ) {
            $full_name = 'Noise_' . $pattern . '_25519_ChaChaPoly_SHA256';
        }
        my $is_psk_prefix = ( $full_name =~ /^NoisePSK_/ );
        my ( $p_name, $dh, $cipher_name, $hash_name ) = $full_name =~ /^Noise(?:PSK)?_([^_]+)_([^_]+)_([^_]+)_([^_]+)$/;
        die 'Invalid protocol name: ' . $full_name unless $p_name;
        if ( $is_psk_prefix && $p_name !~ /psk/ ) {
            $p_name .= 'psk0';
        }

        # The protocol name used for h_init must be the standard Noise_... format
        my $noise_name = 'Noise_' . $p_name . '_' . $dh . '_' . $cipher_name . '_' . $hash_name;
        $dh_name = $dh;
        $dh_len  = $DH_CONFIG{$dh_name}->{pub_len} or die "Unsupported DH: $dh_name";
        if ( ref $pattern ne 'Noise::Pattern' ) {
            $pattern = Noise::Pattern->new( name => $p_name );
        }
        $symmetric_state = Noise::SymmetricState->new( cipher => $cipher_name, hash => $hash_name );
        $symmetric_state->initialize_symmetric($full_name);    # using full_name matched noise-c Vector 16 better

        # Mix prologue (always mixed, even if empty)
        $symmetric_state->mix_hash($prologue);

        # Process pre-messages
        my $pre = $pattern->pre_msg;

        # Process initiator pre-messages (index 0)
        for my $token ( $pre->[0]->@* ) {
            if ( $token eq 's' ) {
                my $pk = $initiator ? $s : $rs;
                $symmetric_state->mix_hash( $pk->export_key_raw('public') // '' );
            }
            elsif ( $token eq 'e' ) {
                my $pk = $initiator ? $e : $re;
                $symmetric_state->mix_hash( $pk->export_key_raw('public') // '' );
            }
        }

        # Process responder pre-messages (index 1)
        for my $token ( $pre->[1]->@* ) {
            if ( $token eq 's' ) {
                my $pk = $initiator ? $rs : $s;
                $symmetric_state->mix_hash( $pk->export_key_raw('public') // '' );
            }
            elsif ( $token eq 'e' ) {
                my $pk = $initiator ? $re : $e;
                $symmetric_state->mix_hash( $pk->export_key_raw('public') // '' );
            }
        }
    }
    method _new_dh_obj { $DH_CONFIG{$dh_name}->{class}->new() }

    method _dh_generate_key($obj) {
        if ( $dh_name =~ /^P/ ) {
            $obj->generate_key( $DH_CONFIG{$dh_name}->{params} );
        }
        else {
            $obj->generate_key();
        }
    }

    method _dh_import_key( $obj, $raw, $type ) {
        if ( $dh_name =~ /^P/ ) {
            $obj->import_key_raw( $raw, $DH_CONFIG{$dh_name}->{params} );
        }
        else {
            $obj->import_key_raw( $raw, $type );
        }
    }

    method write_message ($payload) {
        my $tokens  = $pattern->msg_seq->[ $msg_idx++ ] or die 'No more messages in pattern';
        my $message = '';
        for my $token (@$tokens) {
            if ( $token eq 'e' ) {
                $e //= $self->_new_dh_obj();
                $self->_dh_generate_key($e) unless $e->is_private;
                my $pub = $e->export_key_raw('public');
                $message .= $pub;
                $symmetric_state->mix_hash($pub);
                $symmetric_state->mix_key($pub) if $pattern->has_psk;
            }
            elsif ( $token eq 's' ) {
                my $pub = $s->export_key_raw('public');
                $message .= $symmetric_state->encrypt_and_hash($pub);
                $symmetric_state->mix_key($pub) if $pattern->has_psk;
            }
            elsif ( $token eq 'ee' ) {    # ee: DH(initiator_e, responder_e)
                die 'ee failed: e or re undefined' unless $e && $re;
                $symmetric_state->mix_key( $e->shared_secret($re) );
            }
            elsif ( $token eq 'es' ) {    # es: DH(initiator_e, responder_s)
                if ($initiator) {
                    die 'es failed: e or rs undefined' unless $e && $rs;
                    $symmetric_state->mix_key( $e->shared_secret($rs) );
                }
                else {
                    die 'es failed: s or re undefined' unless $s && $re;
                    $symmetric_state->mix_key( $s->shared_secret($re) );
                }
            }
            elsif ( $token eq 'se' ) {    # se: DH(initiator_s, responder_e)
                if ($initiator) {
                    die 'se failed: s or re undefined' unless $s && $re;
                    $symmetric_state->mix_key( $s->shared_secret($re) );
                }
                else {
                    die 'se failed: e or rs undefined' unless $e && $rs;
                    $symmetric_state->mix_key( $e->shared_secret($rs) );
                }
            }
            elsif ( $token eq 'ss' ) {    # ss: DH(initiator_s, responder_s)
                die 'ss failed: s or rs undefined' unless $s && $rs;
                $symmetric_state->mix_key( $s->shared_secret($rs) );
            }
            elsif ( $token eq 'psk' ) {
                $symmetric_state->mix_key_and_hash( $psks->[ $psk_idx++ ] // die 'Missing PSK at index ' . $psk_idx );
            }
        }
        return $message . $symmetric_state->encrypt_and_hash($payload);
    }

    method read_message ($message) {
        my $tokens = $pattern->msg_seq->[ $msg_idx++ ] or die 'No more messages in pattern';
        my $pos    = 0;
        for my $token (@$tokens) {
            if ( $token eq 'e' ) {
                my $pub_raw = substr( $message, $pos, $dh_len );
                $pos += $dh_len;
                $re = $self->_new_dh_obj();
                $self->_dh_import_key( $re, $pub_raw, 'public' );
                $symmetric_state->mix_hash($pub_raw);
                if ( $pattern->has_psk ) { $symmetric_state->mix_key($pub_raw); }
            }
            elsif ( $token eq 's' ) {
                my $len = $symmetric_state->cipher_state->has_key ? $dh_len + 16 : $dh_len;
                my $ct  = substr( $message, $pos, $len );
                $pos += $len;
                my $pub_raw = $symmetric_state->decrypt_and_hash($ct);
                $rs = $self->_new_dh_obj();
                $self->_dh_import_key( $rs, $pub_raw, 'public' );
                $symmetric_state->mix_key($pub_raw) if $pattern->has_psk;
            }
            elsif ( $token eq 'ee' ) {    # ee: DH(initiator_e, responder_e)
                die 'ee failed: e or re undefined' unless $e && $re;
                $symmetric_state->mix_key( $e->shared_secret($re) );
            }
            elsif ( $token eq 'es' ) {    # es: DH(initiator_e, responder_s)
                if ($initiator) {
                    die 'es failed: e or rs undefined' unless $e && $rs;
                    $symmetric_state->mix_key( $e->shared_secret($rs) );
                }
                else {
                    die 'es failed: s or re undefined' unless $s && $re;
                    $symmetric_state->mix_key( $s->shared_secret($re) );
                }
            }
            elsif ( $token eq 'se' ) {    # se: DH(initiator_s, responder_e)
                if ($initiator) {
                    die 'se failed: s or re undefined' unless $s && $re;
                    $symmetric_state->mix_key( $s->shared_secret($re) );
                }
                else {
                    die 'se failed: e or rs undefined' unless $e && $rs;
                    $symmetric_state->mix_key( $e->shared_secret($rs) );
                }
            }
            elsif ( $token eq 'ss' ) {    # ss: DH(initiator_s, responder_s)
                die 'ss failed: s or rs undefined' unless $s && $rs;
                $symmetric_state->mix_key( $s->shared_secret($rs) );
            }
            elsif ( $token eq 'psk' ) {
                $symmetric_state->mix_key_and_hash( $psks->[ $psk_idx++ ] // die 'Missing PSK at index ' . $psk_idx );
            }
        }
        my $payload = $symmetric_state->decrypt_and_hash( substr( $message, $pos ) );
        return $payload;
    }
    method split () { $symmetric_state->split() }
};
#
1;
