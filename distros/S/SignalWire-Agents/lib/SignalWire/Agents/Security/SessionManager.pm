package SignalWire::Agents::Security::SessionManager;
use strict;
use warnings;
use Moo;
use JSON ();
use Digest::SHA qw(hmac_sha256_hex);
use MIME::Base64 ();
use Time::HiRes ();

has 'token_expiry_secs' => (
    is      => 'ro',
    default => sub { 900 },  # 15 minutes
);

has 'secret_key' => (
    is      => 'ro',
    default => sub { _random_hex(32) },
);

has '_debug_mode' => (
    is      => 'rw',
    default => sub { 0 },
);

sub _random_hex {
    my ($len) = @_;
    # Use /dev/urandom for cryptographically secure random bytes.
    # Die on failure rather than falling back to weak randomness.
    if (open my $fh, '<:raw', '/dev/urandom') {
        my $bytes;
        my $read = read($fh, $bytes, $len);
        close $fh;
        if (defined $read && $read == $len) {
            return unpack('H*', $bytes);
        }
    }
    die "FATAL: Cannot generate secure random bytes - /dev/urandom unavailable. "
      . "This is required for session security.\n";
}

sub _random_urlsafe {
    my ($len) = @_;
    my $bytes = '';
    for (1 .. $len) {
        $bytes .= chr(int(rand(256)));
    }
    return MIME::Base64::encode_base64url($bytes, '');
}

sub create_session {
    my ($self, $call_id) = @_;
    $call_id //= _random_urlsafe(16);
    return $call_id;
}

sub generate_token {
    my ($self, $function_name, $call_id) = @_;
    my $expiry = int(time()) + $self->token_expiry_secs;
    my $nonce  = _random_hex(8);

    my $message = "$call_id:$function_name:$expiry:$nonce";
    my $signature = hmac_sha256_hex($message, $self->secret_key);

    my $token = "$call_id.$function_name.$expiry.$nonce.$signature";
    return MIME::Base64::encode_base64url($token, '');
}

# Alias
sub create_tool_token {
    my ($self, $function_name, $call_id) = @_;
    return $self->generate_token($function_name, $call_id);
}

sub _timing_safe_compare {
    my ($a, $b) = @_;
    # Compare HMAC of both values for constant-time comparison
    my $key = 'timing-safe-token-comparison';
    my $hmac_a = hmac_sha256_hex($a, $key);
    my $hmac_b = hmac_sha256_hex($b, $key);
    return $hmac_a eq $hmac_b;
}

sub validate_token {
    my ($self, $call_id, $function_name, $token) = @_;

    return 0 unless $call_id && $function_name && $token;

    my $decoded;
    eval {
        $decoded = MIME::Base64::decode_base64url($token);
    };
    return 0 if $@ || !$decoded;

    my @parts = split(/\./, $decoded);
    return 0 unless @parts == 5;

    my ($token_call_id, $token_function, $token_expiry, $token_nonce, $token_signature) = @parts;

    # Verify function matches
    return 0 unless _timing_safe_compare($token_function, $function_name);

    # Check expiry
    my $expiry = eval { int($token_expiry) };
    return 0 if $@ || !defined $expiry;
    return 0 if $expiry < time();

    # Recreate and verify signature
    my $message = "$token_call_id:$token_function:$token_expiry:$token_nonce";
    my $expected_signature = hmac_sha256_hex($message, $self->secret_key);
    return 0 unless _timing_safe_compare($token_signature, $expected_signature);

    # Verify call_id
    return 0 unless _timing_safe_compare($token_call_id, $call_id);

    return 1;
}

# Alias with different parameter order for backward compat
sub validate_tool_token {
    my ($self, $function_name, $token, $call_id) = @_;
    return $self->validate_token($call_id, $function_name, $token);
}

# Legacy methods - no-ops for API compat
sub activate_session { return 1 }
sub end_session      { return 1 }
sub get_session_metadata  { return {} }
sub set_session_metadata  { return 1 }

sub debug_token {
    my ($self, $token) = @_;
    return { error => 'debug mode not enabled' } unless $self->_debug_mode;

    my $decoded;
    eval { $decoded = MIME::Base64::decode_base64url($token) };
    if ($@ || !$decoded) {
        return {
            valid_format => JSON::false,
            error        => $@ // 'decode failed',
            token_length => defined $token ? length($token) : 0,
        };
    }

    my @parts = split(/\./, $decoded);
    if (@parts != 5) {
        return {
            valid_format => JSON::false,
            parts_count  => scalar @parts,
            token_length => length($token),
        };
    }

    my ($tc, $tf, $te, $tn, $ts) = @parts;
    my $current = int(time());
    my $expiry  = eval { int($te) };
    my $expired = defined $expiry ? ($expiry < $current ? 1 : 0) : undef;

    return {
        valid_format => JSON::true,
        components   => {
            call_id   => (length($tc) > 8 ? substr($tc, 0, 8) . '...' : $tc),
            function  => $tf,
            expiry    => $te,
            nonce     => $tn,
            signature => (length($ts) > 8 ? substr($ts, 0, 8) . '...' : $ts),
        },
        status => {
            current_time       => $current,
            is_expired         => $expired,
            expires_in_seconds => (defined $expiry && !$expired ? $expiry - $current : 0),
        },
    };
}

1;
