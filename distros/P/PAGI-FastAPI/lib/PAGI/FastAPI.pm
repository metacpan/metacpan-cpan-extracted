package PAGI::FastAPI;

use v5.36;
use experimental qw/try for_list/;
use version;

our $VERSION   = qv('v0.1.0');
our $AUTHORITY = 'cpan:MANWAR';

use Future::AsyncAwait;
use JSON::PP qw(encode_json decode_json);
use Scalar::Util qw(blessed);
use PAGI::App::URLMap;
use PAGI::WebSocket;
use PAGI::Middleware::CORS;
use PAGI::FastAPI::Context;
use PAGI::FastAPI::Depends qw(Depends);

=encoding utf-8

=head1 NAME

PAGI::FastAPI - Asynchronous, Type-Safe Micro-Framework with Dependency Injection and OpenAPI & Swagger UI

=head1 VERSION

Version v0.1.0

=head1 SYNOPSIS

    use v5.36;
    use PAGI::FastAPI;
    use PAGI::FastAPI::Depends qw(Depends);
    use Types::Standard qw(Int Str);
    use Future::AsyncAwait;

    my $app = PAGI::FastAPI->new(
        title   => 'Store Microservice',
        version => '1.0.0',
    );

    # 1. Add CORS Support (delegates to PAGI::Middleware::CORS from PAGI::Tools)
    $app->add_cors(
        origins => ['https://example.com'],
        methods => ['GET', 'POST'],
    );

    # 2. Add Authentication Middleware Hook
    #    (hand-rolled here for illustration only, for ready-made schemes,
    #    including proper 401 challenges, see PAGI::FastAPI::Security)
    $app->add_middleware(async sub ($c, $next) {
        my $auth = $c->header('Authorization') // '';
        if ($auth ne 'Bearer secret_token') {
            $c->status(401);
            return { detail => 'Unauthorized' };
        }
        $c->stash->{user_id} = 42;
        return await $next->($c);
    });

    # 3. Register Lifespan Handlers
    $app->on_startup(async sub {
        warn "Connecting to database connection pool...\n";
    });

    $app->on_shutdown(async sub {
        warn "Closing database connections...\n";
    });

    # 4. Declare Async Dependencies
    my $get_db = async sub ($c) {
        return { db_name => 'production_db' };
    };

    my $get_current_user = async sub ($c) {
        my $token = $c->header('Authorization') // '';
        unless ($token eq 'Bearer secret_token') {
            $c->status(401);
            return { detail => 'Invalid credentials' };
        }
        return { user_id => 42, role => 'admin' };
    };

    # 5. Route using HashRef Dependency Map
    $app->get('/profile',
        dependencies => {
            db   => $get_db,
            user => $get_current_user,
        },
        handler => async sub ($c) {
            my $db   = $c->stash->{db};
            my $user = $c->stash->{user};
            return { user => $user, db => $db->{db_name} };
        }
    );

    # 6. Route using Depends() Array Spec
    $app->get('/admin',
        dependencies => [
            Depends($get_current_user, key => 'user'),
            async sub ($c) {
                if ($c->stash->{user}{role} ne 'admin') {
                    $c->status(403);
                    return { detail => 'Admin privileges required' };
                }
            }
        ],
        handler => async sub ($c) {
            return { message => 'Welcome to admin panel' };
        }
    );

    # 7. Non-blocking GET route with path parameter & query validation
    $app->get('/items/{id}',
        query   => { limit => Int },
        handler => async sub ($c) {
            return {
                item_id => $c->param('id'),
                limit   => $c->param('limit'),
                status  => 'active',
            };
        }
    );

    # 8. Non-blocking POST route with JSON payload validation
    $app->post('/items',
        body    => { name => Str, price => Int },
        handler => async sub ($c) {
            return {
                created => 1,
                name    => $c->body('name'),
                price   => $c->body('price'),
            };
        }
    );

    # 9. Non-blocking WebSocket Endpoint
    # $ws is a PAGI::WebSocket (from PAGI::Tools), so on_close/each_json/
    # try_send_json/keepalive and more are all built in.
    $app->websocket('/ws', handler => async sub ($ws, $deps) {
        await $ws->accept;

        $ws->on_close(async sub {
            my ($code, $reason) = @_;
            # runs on every disconnect path, not just a clean loop exit
        });

        await $ws->each_json(async sub {
            my ($data) = @_;
            await $ws->send_json({ echo => $data });
        });
    });

    # 10. Authentication via the companion PAGI::FastAPI::Security distribution
    #     (extraction only, you supply the verification logic)
    #
    #     use PAGI::FastAPI::Security::HTTPBearer;
    #     my $bearer = PAGI::FastAPI::Security::HTTPBearer->new;
    #     $app->get('/secure',
    #         dependencies => [ $bearer->depends(key => 'token') ],
    #         handler      => async sub ($c) {
    #             return { token => $c->stash->{token} };
    #         }
    #     );
    #
    #     See L<PAGI::FastAPI::Security> for HTTP Basic, API Key
    #     (header/query/cookie), and OAuth2 password-bearer schemes.

    my $pagi_app = $app->to_app;


=head1 DESCRIPTION

C<PAGI::FastAPI> is an asynchronous micro-framework for modern Perl (5.36+) inspired by Python's FastAPI.

It combines non-blocking async execution via L<Future::AsyncAwait> on the
L<PAGI> (Perl Asynchronous Gateway Interface) specification with request
parameter validation via L<Type::Tiny> and automatic interactive
documentation generation.

=head2 Key Features

=over 4

=item * B<PAGI Protocol Engine:> Asynchronous and non-blocking natively, built for scalable web applications.

=item * B<Sub-App & Static Mounting:> Mount external PAGI applications, file drivers, or sub-routers using L</mount>.

=item * B<WebSocket Support:> Full non-blocking WebSocket handshake and frame streaming via L<PAGI::WebSocket>.

=item * B<CORS:> C<add_cors> delegates to L<PAGI::Middleware::CORS> (from L<PAGI::Tools>) rather than a separate implementation.

=item * B<Automatic Type Validation:> Request query parameters and JSON payloads are checked against L<Type::Tiny> constraints before reaching route handlers.

=item * B<Automatic Interactive Docs:> Serves an interactive Swagger UI interface at C</docs> and machine-readable OpenAPI 3.1 JSON at C</openapi.json>.

=item * B<HTTP 422 Interception:> Automatically intercepts invalid or missing parameters and returns formatted JSON errors with an C<HTTP 422 Unprocessable Entity> status code.

=item * B<Pluggable Authentication:> Authentication is implemented as ordinary dependencies and middleware, with no framework lock-in. For ready-made schemes (HTTP Bearer, HTTP Basic, API Key, OAuth2 password bearer), see the companion distribution L<PAGI::FastAPI::Security>, see L</AUTHENTICATION AND SECURITY> below.

=back

=head1 METHODS

=head2 C<new(%options)>

    my $app = PAGI::FastAPI->new(
        title   => 'My API',
        version => '1.2.3',
    );

Instantiates a new C<PAGI::FastAPI> instance. Acceptable options:

=over 4

=item * C<title> - (Optional) Title string for the application and OpenAPI specification. Default: C<'PAGI::FastAPI Application'>.

=item * C<version> - (Optional) Version string for the OpenAPI specification. Default: C<'$VERSION'>.

=back

=head2 C<get($path, %options)>

=head2 C<post($path, %options)>

=head2 C<put($path, %options)>

=head2 C<patch($path, %options)>

=head2 C<delete($path, %options)>

Registers a route for the specified HTTP verb. Options include:

=over 4

=item * C<query> - (Optional) HashRef mapping query string keys to L<Type::Tiny> type constraints.

=item * C<body> - (Optional) HashRef mapping request body keys to L<Type::Tiny> type constraints. The request body is parsed as JSON by default; if the C<Content-Type> header is C<application/x-www-form-urlencoded>, it is parsed as form-urlencoded data instead. Either way, the same type constraints and validation apply.

=item * C<dependencies> - (Optional) HashRef or ArrayRef of dependency code blocks or L<PAGI::FastAPI::Depends> specs.

=item * C<handler> - (Required) An C<async sub ($c)> code reference executing business logic. Receives a L<PAGI::FastAPI::Context> instance.

=back

=cut

sub new ($class, %args) {
    return bless {
        title          => $args{title}   // 'PAGI::FastAPI Application',
        version        => $args{version} // $VERSION,
        routes         => [],
        middlewares    => [],
        mounts         => [],
        cors_options   => undef,
        event_handlers => {
            startup  => [],
            shutdown => [],
        },
        openapi => {
            openapi => '3.1.0',
            info    => {
                title   => $args{title}   // 'PAGI::FastAPI Application',
                version => $args{version} // $VERSION,
            },
            paths => {},
        }
    }, $class;
}

=head2 C<mount($path_prefix, $pagi_app)>

    $app->mount('/css', PAGI::App::File->new(root => './public/css')->to_app);
    $app->mount('/api/v2', $v2_sub_app);

Mounts a standalone PAGI application closure or sub-application under the given path prefix.
Under the hood, C<to_app()> composes mounted applications using L<PAGI::App::URLMap>.

=cut

sub mount ($self, $path, $app) {
    $path = "/$path" unless $path =~ m{^/};
    $path =~ s{/$}{} unless $path eq '/';

    push @{ $self->{mounts} }, {
        prefix => $path,
        app    => $app,
    };

    return $self;
}

sub get    ($self, $path, %opts) { $self->_register_route('GET',    $path, \%opts) }
sub post   ($self, $path, %opts) { $self->_register_route('POST',   $path, \%opts) }
sub put    ($self, $path, %opts) { $self->_register_route('PUT',    $path, \%opts) }
sub patch  ($self, $path, %opts) { $self->_register_route('PATCH',  $path, \%opts) }
sub delete ($self, $path, %opts) { $self->_register_route('DELETE', $path, \%opts) }

=head2 C<on_startup($code_ref)>

=head2 C<on_shutdown($code_ref)>

=head2 C<on_event($event_type, $code_ref)>

Registers async callbacks for PAGI Lifespan Protocol events (C<'startup'> or C<'shutdown'>).

=cut

sub on_event ($self, $event_type, $code) {
    die "Event type must be 'startup' or 'shutdown'"
        unless $event_type =~ /^(?:startup|shutdown)$/;
    die "Event handler must be a CODE reference"
        unless ref $code eq 'CODE';
    push @{$self->{event_handlers}{$event_type}}, $code;
}

sub on_startup  ($self, $code) { $self->on_event('startup',  $code) }
sub on_shutdown ($self, $code) { $self->on_event('shutdown', $code) }

=head2 C<add_middleware($code_ref)>

Registers an asynchronous middleware with the application. Signature:

    $app->add_middleware(async sub ($c, $next) {
        # Pre-processing...
        my $res = await $next->($c);
        # Post-processing...
        return $res;
    });

=cut

sub add_middleware ($self, $code_ref) {
    push @{$self->{middlewares}}, $code_ref;
}

=head2 C<add_cors(%options)>

Enables Cross-Origin Resource Sharing (CORS), including automatic handling
of C<OPTIONS> preflight requests, by delegating to L<PAGI::Middleware::CORS>
(from L<PAGI::Tools>) rather than a hand-rolled implementation, see that
module's own documentation for the authoritative behaviour.
Options (matching L<PAGI::Middleware::CORS>'s own names exactly, so they
mean the same thing here as anywhere else in the PAGI ecosystem):

=over 4

=item * C<origins> - ArrayRef of allowed origins (default: C<['*']>).

=item * C<methods> - ArrayRef of allowed HTTP methods
(default: C<['GET','POST','PUT','DELETE','PATCH','OPTIONS']>).

=item * C<headers> - ArrayRef of allowed request headers
(default: C<['Content-Type','Authorization','X-Requested-With']>).

=item * C<expose_headers> - ArrayRef of headers to expose to the client (default: C<[]>).

=item * C<credentials> - Boolean enabling credentials support (default: C<0>).

=item * C<max_age> - Preflight cache max age in seconds (default: C<86400>).

=back

B<Changed in v0.1.0>: previously this took C<allow_origins>/C<allow_methods>/
C<allow_headers>/C<allow_credentials> and implemented CORS handling directly
in C<PAGI::FastAPI>. It's now a thin wrapper that hands your options straight
to L<PAGI::Middleware::CORS>, so the option names above match that module's
exactly.

=cut

sub add_cors ($self, %opts) {
    $self->{cors_options} = \%opts;
}

=head2 C<websocket($path, %options)>

    $app->websocket('/ws/{room}',
        handler => async sub ($ws, $deps) {
            await $ws->accept;
            while (defined(my $msg = await $ws->receive_text)) {
                await $ws->send_text("Room $ws->path_params->{room}: $msg");
            }
        }
    );

Registers a WebSocket endpoint at C<$path>. The C<handler> receives a L<PAGI::WebSocket> instance
(from L<PAGI::Tools>, the reference WebSocket wrapper for the PAGI spec) and an optional HashRef of
resolved dependencies.

=cut

sub websocket {
    my ($self, $path, %args) = @_;

    my $handler = delete $args{handler};
    my $deps    = delete $args{dependencies} // [];

    die "Route 'WEBSOCKET $path' requires a 'handler' async coderef"
        unless ref $handler eq 'CODE';

    # Package arguments into a single options HashRef
    my %opts = (
        dependencies => $deps,
        handler      => $handler,
        %args,
    );

    # Pass 4 positional arguments to match _register_route ($self, $method, $path, $opts)
    $self->_register_route('WEBSOCKET', $path, \%opts);

    return $self;
}

=head2 C<to_app()>

    my $pagi_closure = $app->to_app;

Generates and returns an asynchronous code reference conforming to the PAGI
protocol specification. If sub-applications were registered via L</mount>,
C<to_app()> automatically wraps the routes using L<PAGI::App::URLMap>.

=cut

sub to_app ($self) {
    my $fastapi_app = $self->_build_pagi_app;

    my $final_app = $fastapi_app;

    if (@{ $self->{mounts} }) {
        my $urlmap = PAGI::App::URLMap->new;

        for my $m (@{ $self->{mounts} }) {
            $urlmap->mount($m->{prefix} => $m->{app});
        }

        $urlmap->mount('/' => $fastapi_app);

        $final_app = $urlmap->to_app;
    }

    # Applied outermost, after mounts, so CORS headers/preflight handling
    # cover every route, including mounted sub-apps and static files, not
    # just routes registered directly on this app.
    if ($self->{cors_options}) {
        $final_app = PAGI::Middleware::CORS->new(%{ $self->{cors_options} })
                                           ->wrap($final_app);
    }

    return $final_app;
}

sub _build_pagi_app ($self) {
    return async sub ($scope, $receive, $send) {
        if ($scope->{type} eq 'websocket') {
            return await $self->_handle_websocket($scope, $receive, $send);
        # Handle PAGI Lifespan Protocol (startup & shutdown)
        } elsif ($scope->{type} eq 'lifespan') {
            while (1) {
                my $event = await $receive->();
                if ($event->{type} eq 'lifespan.startup') {
                    try {
                        for my $cb (@{$self->{event_handlers}{startup}}) {
                            await $cb->();
                        }
                        await $send->({ type => 'lifespan.startup.complete' });
                    }
                    catch ($err) {
                        await $send->({ type => 'lifespan.startup.failed', message => "$err" });
                        return;
                    }
                }
                elsif ($event->{type} eq 'lifespan.shutdown') {
                    try {
                        for my $cb (@{$self->{event_handlers}{shutdown}}) {
                            await $cb->();
                        }
                        await $send->({ type => 'lifespan.shutdown.complete' });
                    }
                    catch ($err) {
                        await $send->({ type => 'lifespan.shutdown.failed', message => "$err" });
                    }
                    last;
                }
            }
            return;
        }

        die "Unsupported type: $scope->{type}" unless $scope->{type} eq 'http';

        my $path   = $scope->{path} // '/';
        my $method = uc($scope->{method} // 'GET');

        if ($path eq '/docs') {
            await $send->({ type => 'http.response.start', status => 200, headers => [['content-type', 'text/html; charset=utf-8']] });
            await $send->({ type => 'http.response.body',  body => $self->_swagger_ui_html });
            return;
        }

        if ($path eq '/openapi.json') {
            await $send->({ type => 'http.response.start', status => 200, headers => [['content-type', 'application/json']] });
            await $send->({ type => 'http.response.body',  body => encode_json($self->{openapi}) });
            return;
        }

        # Safe Query String Parsing (application/x-www-form-urlencoded)
        my %query_params;
        if (defined $scope->{query_string} && length $scope->{query_string}) {
            for my $pair (split '&', $scope->{query_string}) {
                my ($k, $v) = split '=', $pair, 2;
                $query_params{_uri_unescape($k)} = _uri_unescape($v // '');
            }
        }

        my $body_data;
        if ($method eq 'POST' || $method eq 'PUT' || $method eq 'PATCH') {
            my $raw_body = '';
            while (1) {
                my $event = await $receive->();
                if ($event->{type} eq 'http.request') {
                    $raw_body .= $event->{body} // '';
                    last unless $event->{more_body};
                }
                else {
                    # e.g. 'http.disconnect' or any other event the server
                    # may emit mid-stream: stop waiting rather than loop forever.
                    last;
                }
            }

            if (length $raw_body) {
                # Determine how to decode the body from Content-Type. Default
                # (missing/unrecognised Content-Type) remains JSON.
                my $content_type = '';
                for my $h (@{ $scope->{headers} // [] }) {
                    if (lc($h->[0]) eq 'content-type') {
                        $content_type = lc($h->[1] // '');
                        last;
                    }
                }

                if (index($content_type, 'application/x-www-form-urlencoded') == 0) {
                    my %form;
                    for my $pair (split '&', $raw_body) {
                        my ($k, $v) = split '=', $pair, 2;
                        next unless defined $k && length $k;
                        $form{_uri_unescape($k)} = _uri_unescape($v // '');
                    }
                    $body_data = \%form;
                }
                else {
                    try {
                        $body_data = decode_json($raw_body);
                    }
                    catch ($err) {
                        await $send->({ type => 'http.response.start', status => 422, headers => [['content-type', 'application/json']] });
                        await $send->({ type => 'http.response.body',  body => encode_json({ detail => 'Invalid JSON body payload' }) });
                        return;
                    }
                }
            }
        }

        my $ctx = PAGI::FastAPI::Context->new(
            query_params => \%query_params,
            body         => $body_data,
            scope        => $scope,
        );

        my $dispatcher = async sub ($c) {
            for my $route (@{$self->{routes}}) {
                next unless $route->{method} eq $method;

                if (my @captures = ($path =~ $route->{regex})) {
                    my %path_params;
                    my %query_params_validated;

                    for my $i (0 .. $#{$route->{path_params}}) {
                        $path_params{$route->{path_params}[$i]} = _uri_unescape($captures[$i]);
                    }
                    $c->{path_params} = \%path_params;

                    for my ($param, $type) (%{$route->{query_types}}) {
                        my $val = $query_params{$param};
                        if (my $err = $type->validate($val)) {
                            $c->status(422);
                            return { detail => "Query param '$param' invalid: $err" };
                        }
                        my $t_name = eval { $type->name } // '';
                        $query_params_validated{$param} = $type->has_coercion ? $type->coerce($val) : (($t_name eq 'Int') ? $val + 0 : $val);
                    }
                    $c->{query_params} = \%query_params_validated;

                    if (defined $route->{body_spec}) {
                        my $spec = $route->{body_spec};

                        if (blessed($spec) && $spec->can('validate')) {
                            if (my $err = $spec->validate($c->body)) {
                                $c->status(422);
                                return { detail => "Body validation failed: $err" };
                            }
                            if ($spec->has_coercion) {
                                $c->{body} = $spec->coerce($c->body);
                            }
                        }
                        elsif (ref $spec eq 'HASH') {
                            unless (ref $c->body eq 'HASH') {
                                $c->status(422);
                                return { detail => 'Expected a JSON object in request body' };
                            }

                            for my ($field, $type) (%$spec) {
                                my $val = $c->body($field);
                                if (my $err = $type->validate($val)) {
                                    $c->status(422);
                                    return { detail => "Body field '$field' invalid: $err" };
                                }
                                if ($type->has_coercion) {
                                    $c->{body}{$field} = $type->coerce($val);
                                }
                            }
                        }
                    }

                    for my $dep (@{$route->{dependencies}}) {
                        my $dep_res = await $dep->{code}->($c);

                        if ($c->status >= 400) {
                            return $dep_res // { detail => 'Dependency execution failed' };
                        }

                        if (defined $dep->{key} && defined $dep_res) {
                            $c->stash->{$dep->{key}} = $dep_res;
                        }
                    }

                    return await $route->{handler}->($c);
                }
            }

            $c->status(404);
            return { detail => 'Not Found' };
        };

        my $pipeline = $dispatcher;
        for my $mw (reverse @{$self->{middlewares}}) {
            my $next_stage = $pipeline;
            $pipeline = async sub ($c) {
                return await $mw->($c, $next_stage);
            };
        }

        my $res = await $pipeline->($ctx);

        my $response_body_str = '';
        if (defined $res) {
            $response_body_str = ref $res ? encode_json($res) : "$res";
        }

        my @res_headers = (
            (ref $res ? (['content-type', 'application/json']) : ()),
            @{$ctx->res_headers}
        );

        await $send->({
            type    => 'http.response.start',
            status  => $ctx->status,
            headers => \@res_headers,
        });

        await $send->({
            type => 'http.response.body',
            body => $response_body_str,
        });
    };
}

# PRIVATE METHODS

# Minimal application/x-www-form-urlencoded decoder ('+' -> space, %XX -> byte).
# Avoids adding a URI::Escape dependency for this one bit of logic.
sub _uri_unescape ($str) {
    return $str unless defined $str;
    $str =~ tr/+/ /;
    $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
    return $str;
}

async sub _handle_websocket ($self, $scope, $receive, $send) {
    my $raw_path = $scope->{path} // '/';
    my ($route, $path_params) = $self->_match_route('WEBSOCKET', $raw_path);

    # Route Not Found -> Reject with 404 close code before accepting handshake
    unless ($route) {
        $scope->{path_params} = {};
        my $ws = PAGI::WebSocket->new($scope, $receive, $send);
        await $ws->close(4004, "Not Found");
        return;
    }

    $scope->{path_params} = $path_params // {};
    my $ws = PAGI::WebSocket->new($scope, $receive, $send);

    # Resolve dependencies only if defined and non-empty
    my $resolved_deps = {};
    if ($route->{dependencies} && @{$route->{dependencies}}) {
        try {
            # Execute route dependencies
            for my $dep (@{$route->{dependencies}}) {
                my $res = await $dep->{code}->($ws);
                if (defined $dep->{key}) {
                    $resolved_deps->{$dep->{key}} = $res;
                }
            }
        }
        catch ($err) {
            await $ws->close(1008, "Unauthorized: $err");
            return;
        }
    }

    # Execute endpoint handler
    my $handler = $route->{handler};
    try {
        await $handler->($ws, $resolved_deps);
    }
    catch ($err) {
        if (!$ws->is_closed) {
            await $ws->close(1011, "Internal Server Error");
        }
    }
}

sub _match_route ($self, $method, $path) {
    for my $route (@{$self->{routes}}) {
        next unless $route->{method} eq $method;

        if (my @captures = ($path =~ $route->{regex})) {
            my %path_params;
            for my $i (0 .. $#{$route->{path_params}}) {
                $path_params{$route->{path_params}[$i]} = _uri_unescape($captures[$i]);
            }
            return ($route, \%path_params);
        }
    }
    return (undef, {});
}

sub _register_route ($self, $method, $path, $opts) {
    my $query_types = $opts->{query}   // {};
    my $body_spec   = $opts->{body};
    my $raw_deps    = $opts->{dependencies} // [];
    my $handler     = $opts->{handler};

    die "Route '$method $path' requires a 'handler' async coderef"
        unless ref $handler eq 'CODE';

    die "Route '$method $path' 'dependencies' must be a HashRef or ArrayRef"
        unless ref $raw_deps eq 'HASH' || ref $raw_deps eq 'ARRAY';

    my @dependencies;
    if (ref $raw_deps eq 'HASH') {
        for my ($key, $code) (%$raw_deps) {
            die "Route '$method $path' dependency '$key' must be a CODE reference"
                unless ref $code eq 'CODE';
            push @dependencies, { key => $key, code => $code };
        }
    } elsif (ref $raw_deps eq 'ARRAY') {
        for my $dep (@$raw_deps) {
            if (blessed($dep) && $dep->isa('PAGI::FastAPI::Depends')) {
                push @dependencies, { key => $dep->key, code => $dep->code };
            } elsif (ref $dep eq 'CODE') {
                push @dependencies, { key => undef, code => $dep };
            } else {
                die "Route '$method $path' has an unrecognized dependency entry "
                  . "(expected CODE ref or PAGI::FastAPI::Depends instance)";
            }
        }
    }

    # Build the route regex by escaping literal path segments (so characters
    # like '.', '+', '?' in a static path are matched literally, not as
    # regex metacharacters) while turning {param} tokens into captures.
    my @path_params;
    my $regex_path = '';
    my $last_pos   = 0;
    while ($path =~ /\{([a-zA-Z_]\w*)\}/g) {
        push @path_params, $1;
        $regex_path .= quotemeta(substr($path, $last_pos, $-[0] - $last_pos));
        $regex_path .= '([^/]+)';
        $last_pos = $+[0];
    }
    $regex_path .= quotemeta(substr($path, $last_pos));
    $regex_path = "^$regex_path\$";

    # WebSocket routes have no place in an OpenAPI 3.1 document (valid path
    # operations are get/put/post/delete/options/head/patch/trace), so skip
    # the schema bookkeeping below entirely for them.
    if ($method ne 'WEBSOCKET') {
        my @parameters;
        for my $param (@path_params) {
            push @parameters, {
                name     => $param,
                in       => 'path',
                required => \1,
                schema   => { type => 'string' }
            };
        }
        for my ($param, $type) (%$query_types) {
            my $t_name = eval { $type->name } // '';
            push @parameters, {
                name     => $param,
                in       => 'query',
                required => \1,
                schema   => { type => ($t_name eq 'Int' ? 'integer' : 'string') }
            };
        }

        my $route_doc = {
            summary    => "$method $path",
            parameters => \@parameters,
            responses  => {
                200 => { description => "Successful Response" },
                422 => { description => "Validation Error" },
            }
        };

        if ($body_spec) {
            my $properties = {};
            if (ref $body_spec eq 'HASH') {
                for my ($k, $t) (%$body_spec) {
                    my $t_name = eval { $t->name } // '';
                    $properties->{$k} = { type => ($t_name eq 'Int' ? 'integer' : 'string') };
                }
            }
            $route_doc->{requestBody} = {
                required => \1,
                content  => {
                    'application/json' => {
                        schema => {
                            type       => 'object',
                            properties => $properties,
                        }
                    }
                }
            };
        }

        $self->{openapi}{paths}{$path}{lc($method)} = $route_doc;
    }

    push @{$self->{routes}}, {
        method       => $method,
        path         => $path,
        regex        => qr/$regex_path/,
        path_params  => \@path_params,
        query_types  => $query_types,
        body_spec    => $body_spec,
        dependencies => \@dependencies,
        handler      => $handler,
    };
}

sub _swagger_ui_html ($self) {
    return <<"HTML";
<!DOCTYPE html>
<html>
<head>
    <title>$self->{title} - Swagger UI</title>
    <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist\@5/swagger-ui.css" />
</head>
<body>
    <div id="swagger-ui"></div>
    <script src="https://unpkg.com/swagger-ui-dist\@5/swagger-ui-bundle.js"></script>
    <script>
        SwaggerUIBundle({ url: '/openapi.json', dom_id: '#swagger-ui' });
    </script>
</body>
</html>
HTML
}

=head1 AUTO-GENERATED ENDPOINTS

C<PAGI::FastAPI> automatically registers the following system endpoints:

=over 4

=item * C<GET /docs> - Serves an interactive Swagger UI web viewer in the browser.

=item * C<GET /openapi.json> - Serves the generated OpenAPI 3.1 schema.

=back

=head1 ERROR HANDLING

When a request fails parameter validation (either query string or JSON/form-urlencoded body),
C<PAGI::FastAPI> short-circuits handler execution and returns C<HTTP 422 Unprocessable Entity>
with a JSON body:

    {
        "detail": "Query param 'priority' invalid: Undef did not pass type constraint"
    }

Unmatched routes return C<HTTP 404 Not Found> with C<{"detail": "Not Found"}>.

=head1 EVENT LOOPS: FUTURE::IO IS THE GOAL, IO::ASYNC IS AN IMPLEMENTATION DETAIL

The PAGI protocol is deliberately silent on which event loop drives it,
that's meant to be an implementation detail of whichever server runs your
app, not part of the application-level contract. L<PAGI::Server>, the
reference server, happens to use L<IO::Async> today, but don't write your
own application code as if that's guaranteed or load-bearing. Prefer
L<Future::IO> for anything loop-driven you write yourself (timers, delays,
periodic tasks) and it keeps working regardless of which backend a given
PAGI server chooses, now or in the future.

For a periodic task (a heartbeat or a cache sweep, anything you'd otherwise
reach for a timer object for), prefer a self-rescheduling coroutine over
constructing an C<IO::Async::Timer::Periodic> (or any other loop-specific
timer class) directly:

    use Future::AsyncAwait;
    use Future::IO;

    async sub heartbeat {
        while (1) {
            await Future::IO->sleep(30);
            ...
        }
    }
    heartbeat()->retain;

No loop object of your own to construct or own, C<< Future::IO->sleep >>
delegates to whatever backend is already configured in the process, whatever
that turns out to be.

B<Why "prefer" and not "always," then?> Pragmatically, the L<Future::IO>
ecosystem is still growing, and not every library has caught up to it yet.
You'll sometimes still need a loop-specific integration for a particular
dependency, most commonly L<Mojo::Pg> or anything else built directly on
L<Mojo::IOLoop>, which predates L<Future::IO> and doesn't use it. Treat the
rest of this section as a workaround for that specific, narrower situation,
not as a description of how C<PAGI::FastAPI> itself works, which it doesn't
depend on.

=head2 Fallback: bridging a Mojo::IOLoop-based dependency

If your handlers depend on a library on a I<different> event loop from
whatever the PAGI server ends up using, concretely, L<Mojo::Pg> or anything
else on L<Mojo::IOLoop>, calling that library's non-blocking/callback API
will do nothing: separate reactors by default don't service each other. The
symptom is a request or C<on_startup>/C<on_shutdown> handler that just hangs
(and, under L<PAGI::Server>, eventually fails with a lifespan-timeout error)
even though the call you're C<await>-ing looks correct.

Conversely, calling that library in blocking mode instead (e.g. plain
C<< $pg->db->query(...) >> with no callback) does fire promptly, but freezes
the I<entire> process, every other in-flight request and WebSocket
connection, for the duration of that call, since it's a real synchronous
call with nothing cooperative about it. This is easy to end up with by
accident: the blocking form is the default/simplest way to call most of
these libraries, and it will work correctly in every manual test with one
client before degrading badly under concurrent load.

The fix, when C<PAGI::Server> happens to be running on L<IO::Async> (which,
again, is an implementation detail you shouldn't assume, but is true of the
reference server today): get L<IO::Async> and the other library's loop onto
the I<same> underlying reactor, so a single running loop drives both.

=over 4

=item 1.

To make L<IO::Async> work with the reactor, one must install the
L<IO::Async::Loop::EV> because it is the one used when one installs L<EV>,
which is done by L<Mojo::IOLoop> automatically. Note that installing plain
L<EV> will not work: the constructor used for L<IO::Async::Loop> will not
automatically prefer C<EV> even if it has been installed.

=item 2.

Establish the C<IO_ASYNC_LOOP=EV> variable for the entire process prior to
starting the loop. This is necessary even when the L<IO::Async::Loop> is
created by someone else’s code, for instance, C<pagi-server>.

    IO_ASYNC_LOOP=EV pagi-server your_app.pl

=item 3.

Throughout the whole task, utilise the callback/non-blocking variant of the
API from another library (for example, the command C<< $pg->db->query($sql, @binds, $cb) >>),
using a C<Future> to wrap up every call so that it can be executed using
C<await>-ed like any other command. Consult the information available in the
L<Future::AsyncAwait> regarding the routine C<< Future->new >>/C<< $f->done >>/C<< $f->fail >>
for more information.

=back

Without both (1) and (2), the two reactors remain separate no matter how
correctly you use C<await> on your side.

=head1 AUTHENTICATION AND SECURITY

C<PAGI::FastAPI> has no authentication built in by design, auth needs vary
too much between applications to standardise, so the framework gives you two
general-purpose building blocks instead:

=over 4

=item * B<Middleware> (C<add_middleware>), runs for every request, good
for a single global auth check.

=item * B<Dependencies> (the C<dependencies> route option, or
L<PAGI::FastAPI::Depends>), runs per-route, good for auth that varies
by endpoint (e.g. some routes public, some requiring a token, some
requiring a specific role).

=back

A dependency signals an auth failure the same way any other dependency
signals failure: by calling C<< $c->status($code) >> with a code E<gt>=
400 and returning a body HashRef, which short-circuits the route handler
before it runs:

    my $get_current_user = async sub ($c) {
        my $token = $c->header('Authorization') // '';
        unless ($token eq 'Bearer secret_token') {
            $c->status(401);
            return { detail => 'Invalid credentials' };
        }
        return { user_id => 42, role => 'admin' };
    };

Note that a dependency must signal failure this way, not by C<die>ing,
dependency execution is not wrapped in an C<eval>, so a dying dependency
propagates as an uncaught exception instead of a clean HTTP response.

=head2 Ready-made schemes: PAGI::FastAPI::Security

Writing the token-extraction and 401/403-response boilerplate above by
hand for every scheme gets repetitive. The companion distribution
L<PAGI::FastAPI::Security> provides ready-made, C<Depends()>-compatible
classes for the common HTTP authentication schemes, modelled on Python
FastAPI's C<fastapi.security> module:

=over 4

=item * L<PAGI::FastAPI::Security::HTTPBearer> - C<Authorization: Bearer E<lt>tokenE<gt>>, with a proper C<401> + C<WWW-Authenticate: Bearer> challenge on failure.

=item * L<PAGI::FastAPI::Security::HTTPBasic> - C<Authorization: Basic E<lt>base64E<gt>>, with a C<401> + C<WWW-Authenticate: Basic realm="...">> challenge.

=item * L<PAGI::FastAPI::Security::APIKey> - an API key read from a header, query string parameter, or cookie, with a C<403> on failure.

=item * L<PAGI::FastAPI::Security::OAuth2::PasswordBearer> - OAuth2 bearer-token extraction plus C<token_url>/C<scopes> metadata for future OpenAPI C<securitySchemes> generation.

=back

Each scheme only I<extracts> the credential, it deliberately does not
verify it, so you aren't locked into one JWT library, password-hashing
scheme, or identity provider. Pair it with your own verification as a
second dependency:

    use PAGI::FastAPI::Security::HTTPBearer;
    use PAGI::FastAPI::Depends qw(Depends);

    my $bearer = PAGI::FastAPI::Security::HTTPBearer->new;

    $app->get('/items',
        dependencies => [
            $bearer->depends(key => 'token'),
            Depends(async sub ($c) {
                my $claims = eval { verify_jwt($c->stash->{token}) };
                unless ($claims) {
                    $c->status(401);
                    return { detail => 'Invalid or expired token' };
                }
                return $claims;
            }, key => 'claims'),
        ],
        handler => async sub ($c) {
            return { user_id => $c->stash->{claims}{sub} };
        },
    );

Every scheme also accepts C<auto_error =E<gt> 0>, resolving to C<undef>
instead of short-circuiting, for routes that behave differently for
authenticated vs. anonymous requests. See L<PAGI::FastAPI::Security> for
the full documentation and an end-to-end JWT-verification example.

=head1 SEE ALSO

=over 4

=item * L<PAGI> - Perl Asynchronous Gateway Interface specification.

=item * L<PAGI::App::URLMap> - Routing middleware for prefix-matching PAGI applications.

=item * L<PAGI::WebSocket> - Asynchronous WebSocket connection object (from PAGI::Tools) used by C<websocket()> handlers.

=item * L<PAGI::Middleware::CORS> - CORS middleware (from PAGI::Tools) used by C<add_cors>.

=item * L<Future::IO> - Loop-agnostic async I/O primitives; see L</EVENT LOOPS: FUTURE::IO IS THE GOAL, IO::ASYNC IS AN IMPLEMENTATION DETAIL>.

=item * L<PAGI::FastAPI::Context> - Context object passed to route handlers.

=item * L<PAGI::FastAPI::Depends> - Dependency injection helper.

=item * L<PAGI::FastAPI::Security> - Ready-made authentication schemes (HTTP Bearer, HTTP Basic, API Key, OAuth2 password bearer) for C<dependencies>.

=item * L<DBIx::Class::Async> - Async DBIx::Class integration; see F<eg/dbic_async_integration.pl> for a worked example with this framework.

=item * L<Type::Tiny> - Efficient Perl type constraint system.

=item * L<Future::AsyncAwait> - Async/Await syntax for Perl.

=back

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/PAGI-FastAPI>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/PAGI-FastAPI/issues>.
I will be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PAGI::FastAPI

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/PAGI-FastAPI/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PAGI-FastAPI>

=item * Search MetaCPAN

L<https://metacpan.org/dist/PAGI-FastAPI/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1; # End of PAGI::FastAPI
