package SignalWire::Agents::SWML::Service;
use strict;
use warnings;
use Moo;
use JSON ();
use Digest::SHA qw(hmac_sha256_hex);
use MIME::Base64 ();
use SignalWire::Agents::SWML::Document;
use SignalWire::Agents::SWML::Schema;
use SignalWire::Agents::Logging;

has 'route' => (
    is      => 'rw',
    default => sub { '/' },
);

has 'host' => (
    is      => 'rw',
    default => sub { $ENV{SWML_HOST} // '0.0.0.0' },
);

has 'port' => (
    is      => 'rw',
    default => sub { $ENV{SWML_PORT} // 3000 },
);

has 'basic_auth_user' => (
    is      => 'rw',
    default => sub { $ENV{SWML_BASIC_AUTH_USER} // _random_hex(16) },
);

has 'basic_auth_password' => (
    is      => 'rw',
    default => sub { $ENV{SWML_BASIC_AUTH_PASSWORD} // _random_hex(32) },
);

has 'document' => (
    is      => 'rw',
    default => sub { SignalWire::Agents::SWML::Document->new() },
);

has '_logger' => (
    is      => 'ro',
    default => sub { SignalWire::Agents::Logging->get_logger('signalwire.swml_service') },
);

# Schema-driven verb auto-vivification via AUTOLOAD
our $AUTOLOAD;
my $_schema;

sub _get_schema {
    $_schema //= SignalWire::Agents::SWML::Schema->instance();
    return $_schema;
}

sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;  # strip package name

    return if $method eq 'DESTROY';

    my $schema = _get_schema();
    if ($schema->has_verb($method)) {
        # For 'sleep' verb: takes an integer (milliseconds), not a hashref
        my $section = shift // 'main';
        my $data;
        if ($method eq 'sleep') {
            $data = shift // 0;
            # Ensure it is a numeric value
            $data = int($data);
        } else {
            $data = shift // {};
        }
        $self->document->add_verb($section, $method, $data);
        return $self;
    }

    die "Can't locate method \"$method\" via package \"" . ref($self) . "\"";
}

# Provide can() that knows about schema verbs
sub can {
    my ($self, $method) = @_;
    # Check if it is a regular method first
    my $code = $self->SUPER::can($method);
    return $code if $code;
    # Check schema verbs
    my $schema = _get_schema();
    if ($schema && $schema->has_verb($method)) {
        return sub { $self->$method(@_) };
    }
    return undef;
}

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
    die "FATAL: Cannot generate secure random bytes - /dev/urandom unavailable or read failed. "
      . "Set SWML_BASIC_AUTH_USER and SWML_BASIC_AUTH_PASSWORD environment variables instead.\n";
}

sub _timing_safe_compare {
    my ($a, $b) = @_;
    # Compare HMAC of both values with a fixed key for constant-time comparison
    my $key = 'timing-safe-comparison-key';
    my $hmac_a = hmac_sha256_hex($a, $key);
    my $hmac_b = hmac_sha256_hex($b, $key);
    return $hmac_a eq $hmac_b;
}

sub _check_basic_auth {
    my ($self, $env) = @_;
    my $auth = $env->{HTTP_AUTHORIZATION} // '';
    return 0 unless $auth =~ /^Basic\s+(.+)$/i;
    my $decoded = MIME::Base64::decode_base64($1);
    my ($user, $pass) = split(/:/, $decoded, 2);
    return 0 unless defined $user && defined $pass;
    return _timing_safe_compare($user, $self->basic_auth_user)
        && _timing_safe_compare($pass, $self->basic_auth_password);
}

sub _security_headers {
    return (
        'X-Content-Type-Options'  => 'nosniff',
        'X-Frame-Options'         => 'DENY',
        'X-XSS-Protection'        => '1; mode=block',
        'Cache-Control'           => 'no-store, no-cache, must-revalidate',
        'Pragma'                  => 'no-cache',
        'Content-Type'            => 'application/json',
    );
}

sub _json_response {
    my ($status, $data) = @_;
    my @headers = _security_headers();
    my $body = JSON::encode_json($data);
    return [$status, \@headers, [$body]];
}

sub _read_body {
    my ($env) = @_;
    my $input = $env->{'psgi.input'};
    return '' unless $input;
    local $/;
    my $body = <$input>;
    return $body // '';
}

sub to_psgi_app {
    my ($self) = @_;

    return sub {
        my ($env) = @_;
        my $method = $env->{REQUEST_METHOD};
        my $path   = $env->{PATH_INFO} // '/';

        # Health/ready endpoints (no auth)
        if ($path eq '/health' || $path eq '/ready') {
            return _json_response(200, { status => 'ok' });
        }

        # Normalize route for matching
        my $route = $self->route;
        $route =~ s{/$}{};       # strip trailing slash
        $path  =~ s{/$}{};       # strip trailing slash
        $route = '' if $route eq '/';
        $path  = '' if $path eq '/';

        # Check if this request matches our routes
        my $is_swml_route   = ($path eq $route);
        my $is_swaig_route  = ($path eq "$route/swaig");
        my $is_post_prompt  = ($path eq "$route/post_prompt");

        if ($is_swml_route || $is_swaig_route || $is_post_prompt) {
            # Require basic auth for protected routes
            unless ($self->_check_basic_auth($env)) {
                return [
                    401,
                    ['Content-Type' => 'text/plain', 'WWW-Authenticate' => 'Basic realm="SignalWire"'],
                    ['Authentication required'],
                ];
            }

            if ($is_swml_route) {
                return $self->_handle_swml_request($env);
            } elsif ($is_swaig_route) {
                return $self->_handle_swaig_request($env);
            } elsif ($is_post_prompt) {
                return $self->_handle_post_prompt($env);
            }
        }

        return _json_response(404, { error => 'Not found' });
    };
}

sub _handle_swml_request {
    my ($self, $env) = @_;
    my $doc = $self->render_swml($env);
    return _json_response(200, $doc);
}

sub render_swml {
    my ($self, $env) = @_;
    return $self->document->to_hash;
}

sub _handle_swaig_request {
    my ($self, $env) = @_;
    return _json_response(200, { response => 'SWAIG endpoint' });
}

sub _handle_post_prompt {
    my ($self, $env) = @_;
    return _json_response(200, { response => 'Post prompt endpoint' });
}

1;
