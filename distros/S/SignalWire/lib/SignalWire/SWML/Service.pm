package SignalWire::SWML::Service;
use strict;
use warnings;
use Moo;
use JSON ();
use Digest::SHA qw(hmac_sha256_hex);
use MIME::Base64 ();
use Scalar::Util ();
use SignalWire::SWML::Document;
use SignalWire::SWML::Schema;
use SignalWire::Logging;

has 'name' => (
    is      => 'rw',
    default => sub { 'service' },
);

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
    default => sub { SignalWire::SWML::Document->new() },
);

# SWAIG tool registry — lifted from AgentBase so any Service (sidecar,
# non-agent verb host) can register and dispatch SWAIG functions.
has 'tools' => (
    is      => 'rw',
    default => sub { {} },
);

has 'tool_order' => (
    is      => 'rw',
    default => sub { [] },
);

has 'routing_callbacks' => (
    is      => 'rw',
    default => sub { {} },
);

has '_logger' => (
    is      => 'ro',
    default => sub { SignalWire::Logging->get_logger('signalwire.swml_service') },
);

# Python parity: schema_utils / verb_registry / security accessors.
# In Python these are instance attributes set in __init__; cross-language
# audit treats them as zero-arg getters. The Perl singletons / lazy-built
# objects expose the same accessor surface.
has 'schema_utils' => (
    is      => 'lazy',
    default => sub { SignalWire::SWML::Schema->instance },
);

has 'verb_registry' => (
    is      => 'lazy',
    default => sub {
        # Tiny stand-in registry for verb-handler dispatch. The Perl SDK
        # uses AUTOLOAD against the schema for verb lookup; this hashref
        # mirrors Python's VerbHandlerRegistry surface (handlers indexed
        # by verb name) so callers can introspect / extend it.
        return { handlers => {} };
    },
);

has 'security' => (
    is      => 'lazy',
    default => sub {
        my ($self) = @_;
        # Python's SWMLService.security is a SecurityConfig instance that
        # bundles SSL + basic-auth + CORS knobs. Perl SWMLService models
        # those as direct ``has`` attributes (basic_auth_user, etc.); the
        # ``security`` accessor returns a hashref view of the same data so
        # cross-port code that reaches into ``$svc->security->{...}`` keeps
        # working. Wrap in a blessed Moo-ish object so introspection still
        # sees it as an object (Python parity).
        require SignalWire::Security::SessionManager;
        return $self->{_session_manager}
            //= SignalWire::Security::SessionManager->new();
    },
);

# Function-name validation pattern matches the other ports.
my $SWAIG_FN_NAME = qr/\A[a-zA-Z_][a-zA-Z0-9_]*\z/;

# Schema-driven verb auto-vivification via AUTOLOAD
our $AUTOLOAD;
my $_schema;

sub _get_schema {
    $_schema //= SignalWire::SWML::Schema->instance();
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

# Validate provided basic-auth credentials. (Python parity:
# AuthMixin.validate_basic_auth(username, password).)
sub validate_basic_auth {
    my ($self, $username, $password) = @_;
    my $u = $self->basic_auth_user;
    my $p = $self->basic_auth_password;
    return 0 unless defined $u && defined $p;
    return _timing_safe_compare($username, $u)
        && _timing_safe_compare($password, $p);
}

# Returns ($user, $password) by default; if $include_source is truthy,
# returns ($user, $password, $source) where $source is "provided",
# "environment", or "generated". (Python parity:
# AuthMixin.get_basic_auth_credentials(include_source=False).)
sub get_basic_auth_credentials {
    my ($self, $include_source) = @_;
    my $user = $self->basic_auth_user // '';
    my $pass = $self->basic_auth_password // '';
    return ($user, $pass) unless $include_source;
    my $env_user = $ENV{SWML_BASIC_AUTH_USER} // '';
    my $env_pass = $ENV{SWML_BASIC_AUTH_PASSWORD} // '';
    my $source;
    if ($env_user ne '' && $env_pass ne '' && $user eq $env_user && $pass eq $env_pass) {
        $source = 'environment';
    } elsif ($user =~ /^user_/ && length($pass) > 20) {
        $source = 'generated';
    } else {
        $source = 'provided';
    }
    return ($user, $pass, $source);
}

# Backward-compat alias for Perl callers that used the named-helper form.
# Equivalent to ``$self->get_basic_auth_credentials(1)``.
sub get_basic_auth_credentials_with_source {
    my ($self) = @_;
    return $self->get_basic_auth_credentials(1);
}

# extract_sip_username($request_body)
#
# Python parity: SWMLService.extract_sip_username(request_body) is a
# @staticmethod that pulls the username out of a SignalWire/SWML
# request body's call.to field. Handles SIP URIs (``sip:user@host``),
# TEL URIs (``tel:+15551234567``), and plain destination strings.
# Returns undef when the body shape doesn't match.
#
# Callable as either a class method or instance method (Perl idiom for
# what Python expresses with @staticmethod). The class_or_self receiver
# is mirrored from FunctionResult and other static-method-shaped helpers.
sub extract_sip_username {
    my ($class_or_self, $request_body) = @_;
    # Allow being called as a free function (single-arg form): if the
    # first arg is itself the request_body hashref, shift it forward.
    if (!defined $request_body && ref $class_or_self eq 'HASH') {
        $request_body = $class_or_self;
    }
    return undef unless ref $request_body eq 'HASH';
    my $call = $request_body->{call};
    return undef unless ref $call eq 'HASH';
    my $to = $call->{to};
    # Python's implementation calls ``to_field.startswith(...)`` which
    # raises AttributeError for non-string values (None / int / list)
    # and returns None via the except path. Mirror that policy: any
    # non-defined or ref value short-circuits to undef.
    return undef unless defined $to && !ref $to;

    if ($to =~ m{^sip:([^@]+)\@}i) {
        return $1;
    }
    if ($to =~ m{^tel:(.+)$}i) {
        return $1;
    }
    return $to;
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
    my $doc = $self->render_main_swml($env);
    return _json_response(200, $doc);
}

# Extension point: render the SWML document for the main path or for
# GET /swaig. Default returns the currently-built Document. AgentBase
# overrides to emit prompt + AI verb at request time.
sub render_main_swml {
    my ($self, $env) = @_;
    return $self->document->to_hash;
}

# Backwards-compatible alias kept for subclasses that override render_swml.
sub render_swml {
    my ($self, $env) = @_;
    return $self->render_main_swml($env);
}

# Customization hook called when SWML is requested. Default delegates to
# on_swml_request and returns its result. Subclasses typically override
# on_swml_request rather than this method.
#
# Return undef to use the default SWML rendering, or a hashref of
# modifications to merge into the rendered document.
#
# Python parity: WebMixin.on_request(request_data, callback_path).
# The Python third `request` argument is FastAPI-specific and
# intentionally not mirrored.
sub on_request {
    my ($self, $request_data, $callback_path) = @_;
    return $self->on_swml_request($request_data, $callback_path);
}

# Customization point for subclasses to modify SWML based on request
# data. The default implementation returns undef (no modification).
#
# Python parity: WebMixin.on_swml_request(request_data, callback_path, request).
# The third ``$request`` parameter mirrors Python's optional FastAPI
# Request object; in Perl this is the PSGI ``$env`` hashref (or a
# wrapper produced by the calling code). Subclasses that don't need
# direct request access can ignore it.
sub on_swml_request {
    my ($self, $request_data, $callback_path, $request) = @_;
    return undef;
}

# ------------------------------------------------------------------
# SWAIG tool registry (lifted from AgentBase)
# ------------------------------------------------------------------

# Define a SWAIG function the AI can call. Tool descriptions and
# parameter descriptions are LLM-facing prompt engineering — see
# PORTING_GUIDE for guidance.
sub define_tool {
    my ($self, %opts) = @_;
    my $name        = $opts{name}
        // die("define_tool requires 'name'");
    my $description = $opts{description} // '';
    my $parameters  = $opts{parameters}  // { type => 'object', properties => {} };
    my $handler     = $opts{handler};

    my $tool_def = {
        function    => $name,
        description => $description,
        parameters  => $parameters,
        (defined $handler ? (_handler => $handler) : ()),
    };
    for my $k (keys %opts) {
        next if $k =~ /^(name|description|parameters|handler)$/;
        $tool_def->{$k} = $opts{$k};
    }
    $self->tools->{$name} = $tool_def;
    push @{ $self->tool_order }, $name
        unless grep { $_ eq $name } @{ $self->tool_order };
    return $self;
}

# Register a raw SWAIG function definition (e.g. from DataMap).
sub register_swaig_function {
    my ($self, $func_def) = @_;
    my $name = $func_def->{function} // die("register_swaig_function needs 'function' key");
    $self->tools->{$name} = $func_def;
    push @{ $self->tool_order }, $name
        unless grep { $_ eq $name } @{ $self->tool_order };
    return $self;
}

# Whether a SWAIG function with the given name is registered.
# (Python parity: ToolRegistry.has_function.)
sub has_function {
    my ($self, $name) = @_;
    return exists $self->tools->{$name} ? 1 : 0;
}

# Get a registered SWAIG function by name, or undef when absent.
# (Python parity: ToolRegistry.get_function.)
sub get_function {
    my ($self, $name) = @_;
    return $self->tools->{$name};
}

# Snapshot of all registered SWAIG functions keyed by name.
# (Python parity: ToolRegistry.get_all_functions.)
sub get_all_functions {
    my ($self) = @_;
    return { %{ $self->tools } };
}

# Remove a registered SWAIG function. Returns 1 on success, 0 if absent.
# (Python parity: ToolRegistry.remove_function.)
sub remove_function {
    my ($self, $name) = @_;
    return 0 unless exists $self->tools->{$name};
    delete $self->tools->{$name};
    @{ $self->tool_order } = grep { $_ ne $name } @{ $self->tool_order };
    return 1;
}

# Register multiple tool definitions at once.
sub define_tools {
    my ($self, @tool_defs) = @_;
    for my $t (@tool_defs) {
        if (ref $t eq 'HASH') {
            if (exists $t->{function}) {
                $self->register_swaig_function($t);
            } else {
                $self->define_tool(%$t);
            }
        }
    }
    return $self;
}

# Dispatch a function call to the registered handler. Default plain
# implementation. AgentBase may override to add token validation.
sub on_function_call {
    my ($self, $name, $args, $raw_data) = @_;
    my $tool = $self->tools->{$name};
    return undef unless $tool && $tool->{_handler};
    return $tool->{_handler}->($args, $raw_data);
}

# List registered SWAIG tool names in registration order.
sub list_tool_names {
    my ($self) = @_;
    return @{ $self->tool_order };
}

# Extension point: invoked between argument parsing and function dispatch
# on POST /swaig. Returns ($target, $short_circuit). If $short_circuit is
# defined, it's encoded as the SWAIG response without calling
# on_function_call. AgentBase may override to add session-token validation.
sub swaig_pre_dispatch {
    my ($self, $request_data, $func_name, $env) = @_;
    return ($self, undef);
}

# Extension point: subclasses may override to add /post_prompt, /mcp etc.
# Receives the relative sub-path (after the route prefix) and parsed body.
# Returns a PSGI response triple, or undef if not handled.
sub handle_additional_route {
    my ($self, $sub_path, $request_data, $env) = @_;
    return undef;
}

# Register a routing callback at a given sub-path under the service route.
sub register_routing_callback {
    my ($self, $path, $cb) = @_;
    $self->routing_callbacks->{$path} = $cb;
    return $self;
}

sub _handle_swaig_request {
    my ($self, $env) = @_;
    my $method = $env->{REQUEST_METHOD} // 'GET';

    if ($method eq 'GET') {
        my $doc = $self->render_main_swml($env);
        return _json_response(200, $doc);
    }

    my $body = _read_body($env);
    my $payload;
    eval { $payload = JSON::decode_json($body) if length($body) };
    if ($@ || !$payload || ref $payload ne 'HASH') {
        return _json_response(400, { error => 'Invalid JSON' });
    }

    my $func_name = $payload->{function};
    if (!defined $func_name || $func_name eq '') {
        return _json_response(400, { error => 'Missing function name' });
    }
    if ($func_name !~ $SWAIG_FN_NAME) {
        return _json_response(400, { error => "Invalid function name format: '$func_name'" });
    }

    # Argument extraction: nested {argument:{parsed:[...]}} OR flat {arguments}
    my $args = {};
    if (ref $payload->{argument} eq 'HASH') {
        my $parsed = $payload->{argument}{parsed};
        $args = $parsed->[0] if ref $parsed eq 'ARRAY' && @$parsed;
    } elsif (ref $payload->{arguments} eq 'HASH') {
        $args = $payload->{arguments};
    }
    $args //= {};

    my ($target, $short_circuit) = $self->swaig_pre_dispatch($payload, $func_name, $env);
    return _json_response(200, $short_circuit) if defined $short_circuit;

    my $result = $target->on_function_call($func_name, $args, $payload);
    return _json_response(404, { error => "Unknown function: $func_name" })
        unless defined $result;

    # FunctionResult-like objects respond to to_hash; handlers may also
    # return plain hashrefs.
    my $result_hash;
    if (ref $result eq 'HASH') {
        $result_hash = $result;
    } elsif (Scalar::Util::blessed($result) && $result->can('to_hash')) {
        $result_hash = $result->to_hash;
    } else {
        $result_hash = { response => "$result" };
    }
    return _json_response(200, $result_hash);
}

sub _handle_post_prompt {
    my ($self, $env) = @_;
    return _json_response(200, { response => 'Post prompt endpoint' });
}

1;
