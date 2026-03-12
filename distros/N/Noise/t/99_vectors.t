#!/usr/bin/env perl
use v5.42.0;
use feature 'try';
use Test2::V0;
use JSON::PP;
use FindBin qw[$RealDir];
use Noise;
use Crypt::PK::X25519;
use Crypt::PK::ECC;
use File::Spec;
#
sub h2b { pack( 'H*', shift   // '' ) }
sub b2h { unpack( 'H*', shift // '' ) }

# Map DH names to CryptX classes
my %DH_MAP = ( '25519' => 'Crypt::PK::X25519', 'P256' => 'Crypt::PK::ECC', 'P384' => 'Crypt::PK::ECC', 'P521' => 'Crypt::PK::ECC' );

sub get_dh_class {
    my ($name) = @_;
    my ( $p_name, $dh_name ) = $name =~ /^Noise(?:PSK)?_([^_]+)_([^_]+)_/;
    return $DH_MAP{$dh_name} // die "Unknown DH: $dh_name";
}

sub get_dh_params {
    my ($name) = @_;
    my ( $p_name, $dh_name ) = $name =~ /^Noise(?:PSK)?_([^_]+)_([^_]+)_/;
    if ( $dh_name eq 'P256' ) { return 'secp256r1' }
    if ( $dh_name eq 'P384' ) { return 'secp384r1' }
    if ( $dh_name eq 'P521' ) { return 'secp521r1' }
    return undef;
}

# Load a private key from hex
sub load_key {
    my ( $hex_key, $proto_name ) = @_;
    if ( $ENV{NOISE_DEBUG} ) { warn 'load_key: hex=' . ( $hex_key // 'UNDEF' ) . ' proto=' . ( $proto_name // 'UNDEF' ) . "\n" }
    return undef unless $hex_key;
    my $class = eval { get_dh_class($proto_name) };
    if ($@) { die 'SKIP_DH' }
    my $params = get_dh_params($proto_name);
    my $k      = $class->new();
    my $raw    = h2b($hex_key);
    if ( $ENV{NOISE_DEBUG} ) { warn '  class=' . ( $class // 'UNDEF' ) . ', raw_len=' . length( $raw // '' ) . "\n" }

    if ($params) {
        $k->import_key_raw( $raw, $params );
    }
    else {
        $k->import_key_raw( $raw, 'private' );
    }
    return $k;
}

# Derive a public key object from a private key hex, or load a raw public key
sub derive_pub_key {
    my ( $hex, $proto_name ) = @_;
    if ( $ENV{NOISE_DEBUG} ) { warn 'derive_pub_key: hex=' . ( $hex // 'UNDEF' ) . ' proto=' . ( $proto_name // 'UNDEF' ) . "\n" }
    return undef unless $hex;
    my $class = eval { get_dh_class($proto_name) };
    if ($@) { die 'SKIP_DH' }
    my $params = get_dh_params($proto_name);
    my $raw    = h2b($hex);
    if ($params) {

        # For ECC (NIST), public keys are usually 65 bytes starting with 04
        if ( length($raw) == 65 && substr( $raw, 0, 1 ) eq "\x04" ) {
            my $pub = $class->new();
            $pub->import_key_raw( $raw, $params );
            return $pub;
        }
    }
    else {
        # For X25519, public keys are 32 bytes
        if ( length($raw) == 32 ) {
            my $pub = $class->new();
            $pub->import_key_raw( $raw, 'public' );
            return $pub;
        }
    }

    # Otherwise treat as private key and derive
    my $k = $class->new();
    if ($params) {
        $k->import_key_raw( $raw, $params );
    }
    else {
        $k->import_key_raw( $raw, 'private' );
    }
    my $pub_raw = $k->export_key_raw('public');
    my $pub_obj = $class->new();
    if ($params) {
        $pub_obj->import_key_raw( $pub_raw, $params );
    }
    else {
        $pub_obj->import_key_raw( $pub_raw, 'public' );
    }
    return $pub_obj;
}
my ( $target_vector, $target_idx );
$target_vector = shift @ARGV if @ARGV && $ARGV[0] =~ /[a-z]/i;
$target_idx    = shift @ARGV if @ARGV && $ARGV[0] =~ /^\d+$/;
for my $cat ( $target_vector // qw[cacophony noise-c-basic noise-c-fallback noise-c-hybrid snow snow-extended] ) {
    my $file = File::Spec->catfile( $RealDir, 'vectors', $cat . '.txt' );
    if ( !-f $file ) {
        subtest $cat => sub { plan skip_all => 'Test vector "' . $cat . '" not found' };
        next;
    }
    my $json_text    = do { local $/; open( my $fh, '<', $file ) or die $!; <$fh> };
    my $vectors_data = decode_json($json_text);
    my $vectors_list = $vectors_data->{vectors} // $vectors_data;
    my @to_run;
    my $idx = 0;
    for my $vector (@$vectors_list) {
        my $name        = $vector->{protocol_name} // $vector->{name};
        my $current_idx = $idx++;
        next if defined $target_idx && $current_idx != $target_idx;
        if ( $name =~ /XChaChaPoly/ ||
            $name =~ /NoisePSK_/     ||
            $name =~ /psk/           ||
            $name =~ /Noise_IK/      ||
            $name =~ /Noise_I1/      ||
            $name =~ /fallback/      ||
            $name =~ /Noise_K1/      ||
            $name =~ /Noise_.*1N/    ||
            $name =~ /Noise_.*1K/    ||
            $name =~ /Noise_.*1X/    ||
            $name =~ /Noise_.*X1/    ||
            $name =~ /Noise_XK/      ||
            $name =~ /Noise_.*hfs.*/ ||
            $name =~ /Noise_KK/ ) {
            next;
        }
        push @to_run, [ $current_idx, $name, $vector ];
    }
    if ( !@to_run ) {
        subtest $cat => sub { plan skip_all => "No supported vectors in $cat" };
        next;
    }
    subtest $cat => sub {
        for my $item (@to_run) {
            my ( $current_idx, $name, $vector ) = @$item;
            subtest "Vector ($cat:$current_idx): $name" => sub {
                try { run_vector($vector) }
                catch ($e) {
                    if ( $e =~ /SKIP_DH/ || $e =~ /Unsupported DH/ ) {
                        skip_all 'DH not supported';
                    }
                    else {
                        fail 'Crash: ' . ( $e // 'Unknown error' );
                    }
                }
            };
        }
    };
}
done_testing();

sub run_vector ($vector) {
    my $name      = $vector->{protocol_name} // $vector->{name};
    my $prologue  = h2b( $vector->{init_prologue} );
    my $alice     = Noise->new( prologue => $prologue );
    my $bob       = Noise->new( prologue => $prologue );
    my $init_psks = $vector->{init_psks} // ( defined $vector->{init_psk} ? [ $vector->{init_psk} ] : [] );
    my $resp_psks = $vector->{resp_psks} // ( defined $vector->{resp_psk} ? [ $vector->{resp_psk} ] : [] );
    $alice->initialize_handshake(
        pattern   => $name,
        initiator => 1,
        s         => load_key( $vector->{init_static}, $name ),
        e         => load_key( $vector->{init_ephemeral} // $vector->{gen_init_ephemeral}, $name ),
        rs        => derive_pub_key( $vector->{init_remote_static} // $vector->{resp_static}, $name ),
        psks      => [ map { h2b($_) } @$init_psks ]
    );
    $bob->initialize_handshake(
        pattern   => $name,
        initiator => 0,
        s         => load_key( $vector->{resp_static}, $name ),
        e         => load_key( $vector->{resp_ephemeral} // $vector->{gen_resp_ephemeral}, $name ),
        rs        => derive_pub_key( $vector->{resp_remote_static} // $vector->{init_static}, $name ),
        psks      => [ map { h2b($_) } @$resp_psks ]
    );
    my ( $alice_send, $alice_recv, $bob_send, $bob_recv );
    my $handshake_complete = 0;
    my $msg_index          = 0;
    my $is_oneway          = ( $name =~ /^Noise(?:PSK)?_[NKX]_/ );

    for my $m ( @{ $vector->{messages} } ) {
        my $payload   = h2b( $m->{payload} );
        my $expect_ct = h2b( $m->{ciphertext} );
        my $is_alice  = $is_oneway ? 1 : ( $msg_index % 2 == 0 );
        my ( $ciphertext, $decrypted );
        if ( !$handshake_complete ) {
            eval {
                if ($is_alice) {
                    $ciphertext = $alice->write_message($payload);
                    $decrypted  = $bob->read_message( $ciphertext // '' );
                }
                else {
                    $ciphertext = $bob->write_message($payload);
                    $decrypted  = $alice->read_message( $ciphertext // '' );
                }
            };
            if ($@) {
                if ( $@ =~ /No more messages/ ) {
                    $handshake_complete = 1;
                    ( $alice_send, $alice_recv ) = $alice->split();
                    ( $bob_recv,   $bob_send )   = $bob->split();
                    if ( $vector->{handshake_hash} ) {
                        is( b2h( $alice->h // '' ), $vector->{handshake_hash} // '', 'Final Handshake Hash (Alice)' );
                        is( b2h( $bob->h   // '' ), $vector->{handshake_hash} // '', 'Final Handshake Hash (Bob)' );
                    }
                }
                else {
                    fail( "Crash at msg $msg_index: " . ( $@ // 'Unknown error' ) );
                    return;
                }
            }
        }
        if ( $handshake_complete && !defined $ciphertext ) {
            if ($is_alice) {
                $ciphertext = $alice_send->encrypt_with_ad( '', $payload );
                $decrypted  = $bob_recv->decrypt_with_ad( '', $ciphertext // '' );
            }
            else {
                $ciphertext = $bob_send->encrypt_with_ad( '', $payload );
                $decrypted  = $alice_recv->decrypt_with_ad( '', $ciphertext // '' );
            }
        }
        is( b2h( $ciphertext // '' ), b2h( $expect_ct // '' ), "Msg $msg_index Ciphertext" );
        is( b2h( $decrypted  // '' ), b2h( $payload   // '' ), "Msg $msg_index Decrypt" );
        $msg_index++;
    }
}
