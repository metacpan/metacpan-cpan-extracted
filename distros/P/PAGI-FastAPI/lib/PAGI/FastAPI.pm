package PAGI::FastAPI;

use v5.38;
use experimental qw/class try for_list/;
use version;

our $VERSION   = qv('v1.2.4');
our $AUTHORITY = 'cpan:MANWAR';

use Future::AsyncAwait;
use JSON::PP qw(encode_json decode_json);
use Scalar::Util qw(blessed);
use PAGI::App::URLMap;
use PAGI::Context;
use PAGI::WebSocket;
use PAGI::Middleware::CORS;
use PAGI::FastAPI::Context;
use PAGI::FastAPI::Depends qw(Depends);
use PAGI::FastAPI::Middleware::RateLimit;

class PAGI::FastAPI {
    field $title          :param = 'PAGI::FastAPI Application';
    field $version        :param = $VERSION;
    field $secret         :param = undef;
    field $routes                  = [];
    field $middlewares             = [];
    field $pagi_middlewares        = [];
    field $mounts                  = [];
    field $cors_options            = undef;
    field $event_handlers          = undef;
    field $openapi                 = undef;

    ADJUST {
        $event_handlers = {
            startup  => [],
            shutdown => [],
        };
        $openapi = {
            openapi => '3.1.0',
            info    => {
                title   => $title,
                version => $version,
            },
            paths   => {},
        };
    }

    method mount ($path, $app) {
        $path = "/$path" unless $path =~ m{^/};
        $path =~ s{/$}{} unless $path eq '/';

        push @$mounts, {
            prefix => $path,
            app    => $app,
        };

        return $self;
    }

    method get    ($path, %opts) { $self->_register_route('GET',    $path, \%opts) }
    method post   ($path, %opts) { $self->_register_route('POST',   $path, \%opts) }
    method put    ($path, %opts) { $self->_register_route('PUT',    $path, \%opts) }
    method patch  ($path, %opts) { $self->_register_route('PATCH',  $path, \%opts) }
    method delete ($path, %opts) { $self->_register_route('DELETE', $path, \%opts) }

    method on_event ($event_type, $code) {
        die "Event type must be 'startup' or 'shutdown'"
            unless $event_type =~ /^(?:startup|shutdown)$/;
        die "Event handler must be a CODE reference"
            unless ref $code eq 'CODE';
        push @{$event_handlers->{$event_type}}, $code;
    }

    method on_startup  ($code) { $self->on_event('startup',  $code) }
    method on_shutdown ($code) { $self->on_event('shutdown', $code) }

    method add_middleware ($mw, %opts) {
        if (!ref $mw) {
            eval "require $mw;" or die $@;
            $mw = $mw->new(%opts);
        }

        if (blessed($mw) && ($mw->can('wrap') || $mw->can('to_app') || $mw->can('call'))) {
            push @$pagi_middlewares, $mw;
        }
        else {
            push @$middlewares, $mw;
        }

        return $self;
    }

    method enable_csrf (%opts) {
        require PAGI::Middleware::CSRF;
        my $csrf_secret = delete $opts{secret} // $secret
            // die "CSRF middleware requires 'secret' option";

        my $mw = PAGI::Middleware::CSRF->new(
            secret  => $csrf_secret,
            enforce => 'header',
            secure  => 0,
            %opts,
        );

        return $self->add_middleware($mw);
    }

    method add_cors (%opts) {
        $cors_options = \%opts;
    }

    method websocket ($path, %args) {
        my $handler = delete $args{handler};
        my $deps    = delete $args{dependencies} // [];

        die "Route 'WEBSOCKET $path' requires a 'handler' async coderef"
            unless ref $handler eq 'CODE';

        my %opts = (
            dependencies => $deps,
            handler      => $handler,
            %args,
        );

        $self->_register_route('WEBSOCKET', $path, \%opts);

        return $self;
    }

    method add_rate_limit (%opts) {
        my $limiter = PAGI::FastAPI::Middleware::RateLimit->new(%opts);
        $self->add_middleware(async sub ($c, $next) {
            return await $limiter->handle($c, $next);
        });
        return $self;
    }

    method add_bot_protection (%opts) {
        use PAGI::FastAPI::Middleware::BotProtection;
        my $guard = PAGI::FastAPI::Middleware::BotProtection->new(%opts);

        $self->add_middleware(async sub ($c, $next) {
            return await $guard->handle($c, $next);
        });

        return $self;
    }

    method sse ($generator, %opts) {
        use PAGI::FastAPI::Response::SSE;
        return PAGI::FastAPI::Response::SSE->new(
            generator => $generator,
            headers   => $opts{headers} // [],
            status    => $opts{status}  // 200,
        );
    }

    method to_pagi () {
        my $app = $self->to_app(); # Get core route/CORS app

        # Wrap PAGI middleware objects in reverse (LIFO order)
        for my $mw (reverse @$pagi_middlewares) {
            if (blessed($mw) && $mw->can('wrap')) {
                $app = $mw->wrap($app);
            }
            elsif (blessed($mw) && $mw->can('to_app')) {
                $app = $mw->to_app($app);
            }
            elsif (ref $mw eq 'CODE') {
                $app = $mw->($app);
            }
        }

        return $app;
    }

    method to_app {
        my $fastapi_app = $self->_build_pagi_app;

        my $final_app = $fastapi_app;

        if (@$mounts) {
            my $urlmap = PAGI::App::URLMap->new;

            for my $m (@$mounts) {
                $urlmap->mount($m->{prefix} => $m->{app});
            }

            $urlmap->mount('/' => $fastapi_app);

            $final_app = $urlmap->to_app;
        }

        if ($cors_options) {
            $final_app = PAGI::Middleware::CORS->new(%$cors_options)
                                               ->wrap($final_app);
        }

        return $final_app;
    }

    method _build_pagi_app {
        return async sub ($scope, $receive, $send) {
            if ($scope->{type} eq 'websocket') {
                return await $self->_handle_websocket($scope, $receive, $send);
            } elsif ($scope->{type} eq 'lifespan') {
                while (1) {
                    my $event = await $receive->();
                    if ($event->{type} eq 'lifespan.startup') {
                        try {
                            for my $cb (@{$event_handlers->{startup}}) {
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
                            for my $cb (@{$event_handlers->{shutdown}}) {
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

            die "Unsupported type: $scope->{type}" unless $scope->{type} =~ /^(?:http|sse|websocket)$/;

            my $path   = $scope->{path} // '/';
            my $method = uc($scope->{method} // 'GET');

            if ($path eq '/docs') {
                await $send->({ type => 'http.response.start', status => 200, headers => [['content-type', 'text/html; charset=utf-8']] });
                await $send->({ type => 'http.response.body',  body => $self->_swagger_ui_html });
                return;
            }

            if ($path eq '/openapi.json') {
                await $send->({ type => 'http.response.start', status => 200, headers => [['content-type', 'application/json']] });
                await $send->({ type => 'http.response.body',  body => encode_json($openapi) });
                return;
            }

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
                        last;
                    }
                }

                if (length $raw_body) {
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

            my $pagi_context = PAGI::Context->new($scope, $receive, $send);
            my $ctx = PAGI::FastAPI::Context->new(
                query_params => \%query_params,
                body         => $body_data,
                scope        => $scope,
                pagi_context => $pagi_context,
            );

            my $dispatcher = async sub ($c) {
                for my $route (@$routes) {
                    next unless $route->{method} eq $method;

                    if (my @captures = ($path =~ $route->{regex})) {
                        my %path_params;
                        my %query_params_validated;

                        for my $i (0 .. $#{$route->{path_params}}) {
                            $path_params{$route->{path_params}[$i]} = _uri_unescape($captures[$i]);
                        }

                        # Store extracted path parameters via Context's constructor state
                        my $p_params = $c->path_params;
                        %$p_params = %path_params;

                        for my ($param, $type) (%{$route->{query_types}}) {
                            my $val = $query_params{$param};
                            if (my $err = $type->validate($val)) {
                                $c->status(422);
                                return { detail => "Query param '$param' invalid: $err" };
                            }
                            my $t_name = eval { $type->name } // '';
                            $query_params_validated{$param} = $type->has_coercion ? $type->coerce($val) : (($t_name eq 'Int') ? $val + 0 : $val);
                        }

                        my $q_params = $c->query_params;
                        %$q_params = %query_params_validated;

                        if (defined $route->{body_spec}) {
                            my $spec = $route->{body_spec};

                            if (blessed($spec) && $spec->can('validate')) {
                                if (my $err = $spec->validate($c->body)) {
                                    $c->status(422);
                                    return { detail => "Body validation failed: $err" };
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
            for my $mw (reverse @$middlewares) {
                my $next_stage = $pipeline;
                $pipeline = async sub ($c) {
                    return await $mw->($c, $next_stage);
                };
            }

            my $res = await $pipeline->($ctx);

            # 1. Check if response is an SSE / Streaming object that handles its own send lifecycle
            if (Scalar::Util::blessed($res) && $res->can('dispatch')) {
                return await $res->dispatch($scope, $receive, $send);
            }

            # 2. Response objects (HTML, Custom Response, etc.)
            if (Scalar::Util::blessed($res) && $res->isa('PAGI::FastAPI::Response')) {
                $res->prepare_headers($ctx);

                await $send->({
                    type    => 'http.response.start',
                    status  => $ctx->status,
                    headers => $ctx->res_headers,
                });

                await $send->({
                    type => 'http.response.body',
                    body => $res->body,
                });

                return;
            }

            # 3. Standard HASH/ARRAY data structures -> JSON
            # 4. Standard unblessed scalars -> Plain text / String output
            my $response_body_str = '';
            my $is_json           = 0;

            if (defined $res) {
                my $reftype = ref $res;
                if ($reftype eq 'HASH' || $reftype eq 'ARRAY') {
                    $response_body_str = encode_json($res);
                    $is_json           = 1;
                }
                elsif (Scalar::Util::blessed($res) && $res->can('TO_JSON')) {
                    $response_body_str = encode_json($res);
                    $is_json           = 1;
                }
                else {
                    $response_body_str = "$res";
                }
            }

            my $has_content_type = grep { lc($_->[0]) eq 'content-type' } @{$ctx->res_headers};

            my @res_headers = (
                ($is_json && !$has_content_type ? (['content-type', 'application/json']) : ()),
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

    sub _uri_unescape ($str) {
        return $str unless defined $str;
        $str =~ tr/+/ /;
        $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
        return $str;
    }

    async method _handle_websocket ($scope, $receive, $send) {
        my $raw_path = $scope->{path} // '/';
        my ($route, $path_params) = $self->_match_route('WEBSOCKET', $raw_path);

        unless ($route) {
            $scope->{path_params} = {};
            my $ws = PAGI::WebSocket->new($scope, $receive, $send);
            await $ws->close(4004, "Not Found");
            return;
        }

        $scope->{path_params} = $path_params // {};
        my $ws = PAGI::WebSocket->new($scope, $receive, $send);

        my $resolved_deps = {};
        if ($route->{dependencies} && @{$route->{dependencies}}) {
            try {
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

    method _match_route ($method, $path) {
        for my $route (@$routes) {
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

    method _register_route ($method, $path, $opts) {
        my $query_types = $opts->{query}   // {};
        my $body_spec   = $opts->{body};
        my $raw_deps    = $opts->{dependencies} // [];
        my $handler     = $opts->{handler};
        my $rl_opts     = $opts->{rate_limit};

        die "Route '$method $path' requires a 'handler' async coderef"
            unless ref $handler eq 'CODE';

        if ($rl_opts) {
            my $limiter = PAGI::FastAPI::Middleware::RateLimit->new(
                ref $rl_opts eq 'HASH' ? %$rl_opts : ()
            );
            my $inner_handler = $handler;
            $handler = async sub ($c) {
                return await $limiter->handle($c, async sub ($ctx) {
                    return await $inner_handler->($ctx);
                });
            };
        }

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

            $openapi->{paths}{$path}{lc($method)} = $route_doc;
        }

        push @$routes, {
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

    method _swagger_ui_html {
        return <<"HTML";
<!DOCTYPE html>
<html>
<head>
    <title>$title - Swagger UI</title>
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
}

=encoding utf-8

=head1 NAME

PAGI::FastAPI - Asynchronous, Type-Safe Micro-Framework with Dependency Injection and OpenAPI & Swagger UI

=head1 VERSION

Version v1.2.4

=head1 SYNOPSIS

    use v5.38;
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

=item * B<PAGI Protocol Engine:> Asynchronous and non-blocking natively,
built for scalable web applications.

=item * B<Sub-App & Static Mounting:> Mount external PAGI applications, file
drivers, or sub-routers using L<mount()|/"C<mount($path_prefix, $pagi_app)>">.

=item * B<WebSocket Support:> Full non-blocking WebSocket handshake and frame
streaming via L<PAGI::WebSocket>.

=item * B<CORS:> C<add_cors> delegates to L<PAGI::Middleware::CORS> (from
L<PAGI::Tools>) rather than a separate implementation.

=item * B<Automatic Type Validation:> Request query parameters and JSON
payloads are checked against L<Type::Tiny> constraints before reaching route
handlers.

=item * B<Automatic Interactive Docs:> Serves an interactive Swagger UI
interface at C</docs> and machine-readable OpenAPI 3.1 JSON at C</openapi.json>.

=item * B<HTTP 422 Interception:> Automatically intercepts invalid or missing
parameters and returns formatted JSON errors with an
C<HTTP 422 Unprocessable Entity> status code.

=item * B<Pluggable Authentication:> Authentication is implemented as ordinary
dependencies and middleware, with no framework lock-in. For ready-made schemes
(HTTP Bearer, HTTP Basic, API Key, OAuth2 password bearer), see the companion
distribution L<PAGI::FastAPI::Security>, see L</AUTHENTICATION AND SECURITY>
below.

=item * B<Rate Limiting:> C<add_rate_limit> and the per-route C<rate_limit>
option provide fixed-window request throttling with pluggable storage
drivers, see L<PAGI::FastAPI::Middleware::RateLimit>.

=item * B<Bot Protection:> C<add_bot_protection> enforces a stateless,
cryptographic proof-of-work challenge/response flow on unauthenticated
requests, see L<PAGI::FastAPI::Middleware::BotProtection>.

=item * B<Server-Sent Events:> C<< $c->sse >> streams production-grade SSE
responses with keepalives and auto-JSON serialisation, see
L<PAGI::FastAPI::Response::SSE>.

=item * B<CSRF Protection:> C<enable_csrf>, plus C<< $c->csrf_token >> and
C<< $c->csrf_verify >>, for form and session-based CSRF defence.

=item * B<Async Message Queue Facade:> L<PAGI::FastAPI::Queue> offers a
pluggable, topic-based C<push>/C<pop>/C<size> queue for use as an ordinary
dependency via C<< $queue->dep >>.

=item * B<Typed Path Parameters:> C<TypedPath()> from
L<PAGI::FastAPI::TypedPath> validates and (optionally) coerces path
parameters via L<Type::Tiny>, the same way C<query>/C<body> already are,
through the existing C<Depends()> mechanism, automatically returning
C<HTTP 422> for a non-matching path segment instead of handing your handler
an unchecked string.

=item * B<Response Shape Filtering:> C<with_response_model()> from
L<PAGI::FastAPI::ResponseModel> validates a handler's return value against
a declared L<Type::Tiny> schema and, for a HashRef-of-fields schema, filters
the output to just the declared fields, so an accidental extra column
from a database row (e.g. a password hash) doesn't leak to the client.

=item * B<Typed Exception Dispatch:> L<PAGI::FastAPI::Middleware::ExceptionHandler>
routes a C<die>-thrown exception to a handler registered for its class,
with a configurable fallback, for the case where an exception escapes a
handler rather than following the C<< $c->status(...) >>-and-return
convention described in L</ERROR HANDLING>.

=item * B<Redirect & File Responses:> L<PAGI::FastAPI::Response::Redirect>
(C<redirect_to()>) and L<PAGI::FastAPI::Response::File> (C<file_response()>)
extend the base L<PAGI::FastAPI::Response> contract for HTTP redirects and
file-download responses, with automatic content-type guessing and
C<Content-Disposition> handling for the latter.

=item * B<Cookie Parsing:> L<PAGI::FastAPI::Cookies> parses the request
C<Cookie> header into a plain HashRef (C<parse_cookies()>, C<cookie()>).
Setting response cookies needs no extra module, C<< $c->add_header('set-cookie' => ...) >>
already works.

=back

=head1 METHODS

=head2 C<new(%options)>

    my $app = PAGI::FastAPI->new(
        title   => 'My API',
        version => '1.2.3',
    );

Instantiates a new C<PAGI::FastAPI> instance. Acceptable named arguments:

=over 4

=item * C<title> - (Optional) Title string for the application and OpenAPI
specification. Default: C<'PAGI::FastAPI Application'>.

=item * C<version> - (Optional) Version string for the OpenAPI specification.
Default: C<'$VERSION'>.

=item * C<secret> - (Optional) Application-level secret scalar. Currently used
as the default C<secret> for L</enable_csrf> when no C<secret> is passed to
that call directly. Storing an app-wide secret here lets you avoid repeating
it at every call site that needs it.

=back

=head2 C<get($path, %options)>, C<post($path, %options)>, C<put($path, %options)>, C<patch($path, %options)>, C<delete($path, %options)>

Registers a route for the specified HTTP verb. Options include:

=over 4

=item * C<query> - (Optional) HashRef mapping query string keys to
L<Type::Tiny> type constraints.

=item * C<body> - (Optional) HashRef mapping request body keys to
L<Type::Tiny> type constraints. The request body is parsed as JSON by
default; if the C<Content-Type> header is C<application/x-www-form-urlencoded>,
it is parsed as form-urlencoded data instead. Either way, the same type
constraints and validation apply.

=item * C<dependencies> - (Optional) HashRef or ArrayRef of dependency code
blocks or L<PAGI::FastAPI::Depends> specs.

=item * C<handler> - (Required) An C<async sub ($c)> code reference executing
business logic. Receives a L<PAGI::FastAPI::Context> instance.

=back

=head2 C<mount($path_prefix, $pagi_app)>

    $app->mount('/css', PAGI::App::File->new(root => './public/css')->to_app);
    $app->mount('/api/v2', $v2_sub_app);

Mounts a standalone PAGI application closure or sub-application under the
given path prefix. Under the hood, C<to_app()> composes mounted applications
using L<PAGI::App::URLMap>.

=head2 C<on_startup($code_ref)>, C<on_shutdown($code_ref)>, C<on_event($event_type, $code_ref)>

Registers async callbacks for PAGI Lifespan Protocol events (C<'startup'> or
C<'shutdown'>).

=head2 C<add_middleware>

    $app->add_middleware($middleware, %opts);

Appends a middleware component to the application's middleware execution stack.

The C<$middleware> parameter can be passed as a class name or an instantiated
object:

=over 4

=item * B<Class Name (String):> Automatically loads the class via C<require>
(dying on load failure) and instantiates it by calling C<< $middleware->new(%opts) >>.

=item * B<Object Instance:> Attached directly. If the object implements PAGI
wrapper interfaces (e.g., C<wrap>, C<to_app>, or C<call>), it is placed into
the PAGI middleware stack; otherwise, it is routed to the legacy/internal
middleware stack.

=back

Returns C<$self> to allow method chaining.

B<Example Usage:>

    # Pass class name with constructor options:
    $app->add_middleware('PAGI::Middleware::Session', secret => 'my-secret');

    # Pass an instantiated middleware object:
    my $mw = PAGI::Middleware::Logger->new(level => 'debug');
    $app->add_middleware($mw);

=head2 C<enable_csrf>

    $app->enable_csrf(%options);

Enables Cross-Site Request Forgery (CSRF) protection on the application by
instantiating and attaching L<PAGI::Middleware::CSRF>.

By default, the middleware is configured with C<enforce =E<gt> 'header'> and
C<secure =E<gt> 0>. Any passed C<%options> override these defaults.

=over 4

=item * C<secret> (Scalar, optional)

The cryptographic secret key used to sign and verify CSRF tokens. If omitted
from C<%options>, it falls back to the application-level C<secret> attribute
set during L<PAGI::FastAPI> instantiation. Dies if no secret can be resolved
from either location.

=item * C<%options> (Hash, optional)

Additional configuration arguments passed directly to L<PAGI::Middleware::CSRF/new>
(such as C<cookie_name>, C<token_length>, or C<secure>).

=back

Returns C<$self> to allow method chaining.

B<Example Usage:>

    # Uses application-level default secret:
    my $app = PAGI::FastAPI->new(secret => 'master-app-secret');
    $app->enable_csrf();

    # Custom secret and production settings:
    $app->enable_csrf(
        secret => 'csrf-specific-secret',
        secure => 1,
    );

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

=item * C<expose_headers> - ArrayRef of headers to expose to the client
(default: C<[]>).

=item * C<credentials> - Boolean enabling credentials support (default: C<0>).

=item * C<max_age> - Preflight cache max age in seconds (default: C<86400>).

=back

B<Changed in v0.1.0>: previously this took C<allow_origins>/C<allow_methods>/
C<allow_headers>/C<allow_credentials> and implemented CORS handling directly
in C<PAGI::FastAPI>. It's now a thin wrapper that hands your options straight
to L<PAGI::Middleware::CORS>, so the option names above match that module's
exactly.

=head2 C<websocket($path, %options)>

    $app->websocket('/ws/{room}',
        handler => async sub ($ws, $deps) {
            await $ws->accept;
            while (defined(my $msg = await $ws->receive_text)) {
                await $ws->send_text("Room $ws->path_params->{room}: $msg");
            }
        }
    );

Registers a WebSocket endpoint at C<$path>. The C<handler> receives a
L<PAGI::WebSocket> instance and an optional HashRef of resolved dependencies.

=head2 C<add_rate_limit(%options)>

    $app->add_rate_limit(
        requests => 100,
        window   => 60, # 100 requests per 60s
        key_cb   => sub ($c) { $c->header('X-API-Key') // '127.0.0.1' },
    );

Registers application-wide rate limiting middleware.

=head2 C<add_bot_protection(%options)>

    $app->add_bot_protection(
        difficulty => 3,
        secret     => $ENV{BOT_PROTECTION_SECRET},
        ttl        => 300,
    );

Enables Proof-of-Work (PoW) bot protection middleware globally across the
application.

When configured, incoming requests lacking valid C<x-bot-challenge> and
C<x-bot-nonce> headers are intercepted and rejected with an HTTP
C<401 Unauthorized> response containing a signed challenge token.
Legitimate client browsers solve the cryptographic puzzle in JavaScript and
retry the request automatically.

Accepts the following named options:

=over 4

=item * C<difficulty> (Optional)

Integer specifying the number of leading zeros required in the calculated
SHA-256 hash collision. Higher values exponentially increase CPU effort for
client devices while keeping server verification costs near-instant.
Defaults to C<3>.

=item * C<secret> (Optional)

A secret seed scalar used to generate HMAC signatures for challenges.
B<Must be customised in production environments> to prevent challenge
tampering or forgery. Defaults to C<'change_me_in_production'>.

=item * C<ttl> (Optional)

Integer specifying the validity duration of generated challenges in seconds.
Defaults to C<300> (5 minutes).

=back

Returns C<$self> to support method chaining.

=head2 C<sse($generator, %options)>

    $app->get('/api/v1/llm-stream', sub ($c) {
        return $c->sse(async sub ($sse) {
            await $sse->keepalive(15);

            for my $token ("Hello", " world!", " SSE!") {
                await $sse->send_json({ token => $token });
                await $c->sleep(0.1);
            }

            await $sse->close;
        });
    });

Returns a C<PAGI::FastAPI::Response::SSE> response object for real-time
Server-Sent Events (SSE) streaming.

Accepts an asynchronous code reference C<$generator> receiving a
L<PAGI::SSE> instance, followed by optional named arguments:

=over 4

=item * C<headers> (Optional)

ArrayRef of additional HTTP headers to include in the handshake response
(e.g., C<< headers => [ ['X-Stream-ID' => '123'] ] >>).

=item * C<status> (Optional)

Integer status code for the initial HTTP handshake response. Defaults to C<200>.

=back

Inside the generator callback, use C<$sse> methods such as C<send_event()>,
C<send_json()>, C<send()>, C<keepalive()>, and C<close()>.

Returns an instance of L<PAGI::FastAPI::Response::SSE>.

=head2 C<to_pagi>

    my $pagi_app = $app->to_pagi();

Compiles the application into a single, executable PAGI-compliant async code
reference ready to be served by an ASGI/PAGI application server (such as
L<PAGI::Server>) or wrapped by L<PAGI::Test::Client>.

This method:

=over 4

=item 1. Builds the core route handling application via C<< $self->to_app() >>.

=item 2. Wraps the application in reverse order (LIFO - Last-In, First-Out)
with all registered PAGI middleware components so that the first added
middleware is executed first on incoming HTTP requests.

=back

Middleware objects are wrapped based on their supported interface:

=over 4

=item * B<Objects with C<wrap>:> Invokes C<< $mw->wrap($app) >>.

=item * B<Objects with C<to_app>:> Invokes C<< $mw->to_app($app) >>.

=item * B<Code references:> Invokes C<< $mw->($app) >>.

=back

Returns an async C<CODEREF> matching the PAGI interface C<< async sub ($scope, $receive, $send) >>.

B<Example Usage:>

    my $app = PAGI::FastAPI->new();
    $app->enable_csrf(secret => 'my-secret');
    $app->get('/health', handler => async sub ($c) { { status => 'ok' } });

    # Compile for server deployment or test runner
    my $pagi_app = $app->to_pagi();

=head2 C<to_app()>

    my $pagi_closure = $app->to_app;

Generates and returns an asynchronous code reference conforming to the PAGI
protocol specification. If sub-applications were registered via
L<mount()|/"C<mount($path_prefix, $pagi_app)>">, C<to_app()> automatically
wraps the routes using L<PAGI::App::URLMap>.

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

The two cases above, and a dependency's own C<< $c->status(...) >>-and-return
convention (see L</AUTHENTICATION AND SECURITY>), cover I<expected> failure
paths. For the separate case of an actual Perl exception (C<die>) escaping
a handler or dependency, e.g. from a database layer or a third-party
module you're calling into, see
L<PAGI::FastAPI::Middleware::ExceptionHandler>, which lets you register a
handler per exception class via C<add_middleware>, with a configurable
fallback for anything unregistered.

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

=item * L<PAGI::FastAPI::Middleware::BotProtection>

=item * L<PAGI::FastAPI::BotProtection::ProofOfWork>

=item * L<PAGI::FastAPI::Response::SSE>

=item * L<PAGI::SSE>

=item * L<PAGI::FastAPI::Middleware::RateLimit> - App-level and per-route rate limiting.

=item * L<PAGI::FastAPI::RateLimit::Driver>, L<PAGI::FastAPI::RateLimit::Driver::Memory> - Pluggable rate-limit storage drivers.

=item * L<PAGI::FastAPI::Queue> - Pluggable async message queue facade.

=item * L<PAGI::FastAPI::Queue::Driver>, L<PAGI::FastAPI::Queue::Driver::Memory> - Pluggable queue storage drivers.

=item * L<PAGI::FastAPI::TypedPath> - Path parameter validation/coercion via C<Depends()>.

=item * L<PAGI::FastAPI::ResponseModel> - Response shape validation and field filtering.

=item * L<PAGI::FastAPI::Middleware::ExceptionHandler> - Typed exception-to-handler dispatch.

=item * L<PAGI::FastAPI::Response::Redirect> - HTTP redirect responses.

=item * L<PAGI::FastAPI::Response::File> - File-download responses.

=item * L<PAGI::FastAPI::Cookies> - Request cookie parsing.

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

=item * Search MetaCPAN

L<https://metacpan.org/dist/PAGI-FastAPI/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0).

=cut

1; # End of PAGI::FastAPI
