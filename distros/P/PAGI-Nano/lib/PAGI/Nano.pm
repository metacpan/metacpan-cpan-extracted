package PAGI::Nano;

use strict;
use warnings;
use Future;
use Future::AsyncAwait;
use Scalar::Util ();
use Carp ();
use JSON::MaybeXS ();
use PAGI::App::Router;
use PAGI::Response;
use PAGI::Context;
use PAGI::Nano::Context::HTTP;
use PAGI::Nano::Context::WebSocket;
use PAGI::Nano::Context::SSE;
use PAGI::Nano::ServiceRegistry;

our $VERSION = '0.001001';

use Exporter 'import';
our @EXPORT = qw(
    app
    get post put patch del any raw
    group mount enable
    startup shutdown
    static not_found
    websocket sse
    name middleware
    service factory
);

# Per-route attribute markers. Both sit in the arrow chain between the path and
# the handler, in any order; an arrayref is shorthand for middleware().
sub name       { my ($n) = @_; bless { name => $n }, 'PAGI::Nano::Marker::Name' }
sub middleware { bless { list => [@_] }, 'PAGI::Nano::Marker::Middleware' }

# A unique, immutable token used to ask an assembled Nano app for its flat
# name->path table. A parent's mount needs a mounted Nano app's named routes,
# but the app is an opaque coderef; calling it with this token alone (instead of
# a real ($scope,$receive,$send) triple) returns the table. This is a constant
# probe key, not shared mutable state — no per-app registry accumulates, so
# building apps leaves nothing behind.
my $ROUTES_PROBE = \do { my $unused };

# A sibling probe token: ask an assembled Nano app whether it declared any
# services (true/false), the same way $ROUTES_PROBE asks for the named-route
# table. mount() uses this to refuse mounting an app that declared services --
# the outermost app owns lifecycle (see mount's shared-state limitation in the
# POD), so a mounted app's own services would never get built.
my $SERVICES_PROBE = \do { my $unused };

# A two-argument probe token: ask an assembled Nano app to resolve one named
# app-scoped service from its retained registry, without issuing a request.
# The registry the startup hook builds is the same object this outer wrapper
# closes over, so once lifespan startup has run its values are reachable here.
# resolve_service() (a test seam) sends this; a real request is always a
# three-element ($scope, $receive, $send) triple, so the two-arg shape never
# collides with one.
my $SERVICE_RESOLVE_PROBE = \do { my $unused };

# The dynamically-scoped current collector. app { } localizes this to a fresh
# collector for the duration of the block; the verbs register into it. No package
# globals leak between app { } invocations, so apps are values: composable,
# nestable, testable, many-per-process. This is the same local-scoped technique
# PAGI::Middleware::Builder's builder { } uses.
our $COLLECTOR;

# --- the collector ----------------------------------------------------------

sub app (&) {
    my ($block) = @_;
    local $COLLECTOR = {
        router       => PAGI::App::Router->new,
        app_mw       => [],
        startup      => [],
        shutdown     => [],
        named        => {},   # name => full path (own routes, group prefixes applied)
        nano_mounts  => [],   # { prefix => ..., app => <Nano app coderef> }
        prefix_stack => [],   # active group prefixes, for naming
        services     => [],   # [name, builder] pairs, in declaration order
    };
    $block->();
    return _assemble($COLLECTOR);
}

sub _assemble {
    my ($collector) = @_;
    my $app = $collector->{router}->to_app;

    $app = _wrap_with_middleware($app, $collector->{app_mw})
        if @{$collector->{app_mw}};

    my $registry = @{$collector->{services}}
        ? PAGI::Nano::ServiceRegistry->new
        : undef;

    if (@{$collector->{startup}} || @{$collector->{shutdown}} || $registry) {
        require PAGI::Lifespan;
        my $lifespan = PAGI::Lifespan->new(app => $app);
        $lifespan->on_startup(_service_startup_hook($registry, $collector->{services}))
            if $registry;
        $lifespan->on_startup($_)  for @{$collector->{startup}};
        $lifespan->on_shutdown($_) for @{$collector->{shutdown}};
        $app = $lifespan->to_app;
    }

    $app = _wrap_with_services($app, $registry) if $registry;

    # Flat name -> absolute-path registry: this app's own named routes plus those
    # of any mounted Nano app (prefixed, recursively via their stored tables).
    my $flat = _build_flat_routes($collector);

    # Nothing to expose or introspect -> no wrapper needed. A services-only app
    # (no named routes) still needs one, purely so mount() can probe it and
    # refuse to mount it (see $SERVICES_PROBE).
    return $app unless %$flat || $registry;

    # Outermost wrapper: inject the registry on each request so $c->uri_for can
    # resolve any name from anywhere. The outermost app wins (//=), so a mounted
    # app sees the parent's fuller, mount-prefixed registry.
    my $inner = $app;
    my $wrapped = sub {
        # Introspection: called with a probe token alone, answer it directly (this
        # is how mount() inspects an opaque mounted app's coderef -- for its named
        # routes, and for whether it declared services at all). A real request is
        # always a ($scope, $receive, $send) triple.
        if (@_ == 1 && ref $_[0]) {
            return $flat            if $_[0] == $ROUTES_PROBE;
            return $registry ? 1 : 0 if $_[0] == $SERVICES_PROBE;
        }
        # The service-resolve probe (a test seam) carries the service name as a
        # second argument. resolve_service only sends it after confirming via
        # $SERVICES_PROBE that the app declared services, so $registry is defined
        # here; the registry croaks, naming the service, on an unknown name.
        if (@_ == 2 && ref $_[0] && $_[0] == $SERVICE_RESOLVE_PROBE) {
            return $registry->service($_[1]);
        }
        my ($scope, $receive, $send) = @_;
        $scope->{'pagi.nano.routes'} //= $flat if ref $scope eq 'HASH';
        return $inner->($scope, $receive, $send);
    };
    return $wrapped;
}

# Ask an opaque app coderef a probe question by calling it with a single
# sentinel token instead of a real ($scope, $receive, $send) triple, and
# return whatever it answers. A non-Nano app (a plain coderef, a PSGI bridge)
# or a Nano app with no probe-answering wrapper either isn't a coderef, dies
# outright (caught below), or -- since it IS a coderef, called with one
# unexpected scalar arg -- ends up treating the token as a malformed scope and
# returns an unready or failed Future; settle that Future here so it isn't
# reported destroyed-unhandled, and answer undef either way. This is the one
# place that Future-lifecycle handling lives; callers each do their own
# one-line coercion of a real answer.
sub _probe {
    my ($app, $token) = @_;
    return undef unless ref $app eq 'CODE';
    my $answer = eval { $app->($token) };
    if (Scalar::Util::blessed($answer) && $answer->isa('Future')) {
        $answer->cancel unless $answer->is_ready;
        $answer->failure if $answer->is_ready && $answer->is_failed;
        return undef;
    }
    return $answer;
}

# Ask an app for its flat Nano name->path table. A Nano app with named routes
# answers the probe token with its table; anything else is reported as nameless.
sub _nano_flat_routes {
    my ($app) = @_;
    my $flat = _probe($app, $ROUTES_PROBE);
    return ref $flat eq 'HASH' ? $flat : undef;
}

# Ask an app whether it declared any services.
sub _nano_has_services {
    my ($app) = @_;
    return _probe($app, $SERVICES_PROBE) ? 1 : 0;
}

# A test seam: resolve one app-scoped service from an assembled Nano app after
# lifespan startup, without issuing a request. Given the app coderef and a
# service name, it sends the two-argument service-resolve probe and returns the
# built value. Only app-scoped services (a plain value or a blessed
# non-factory object) fully resolve without a request; a per-request maker or a
# factory needs a request context, so for those this returns the raw maker
# coderef / factory marker unchanged -- a test needing the per-request value
# must drive a request. Croaks if $app is not a coderef or declared no
# services, and (via the registry) if the name is unknown.
sub resolve_service {
    my ($app, $name) = @_;
    Carp::croak('resolve_service: expected an assembled Nano app coderef')
        unless ref $app eq 'CODE';
    Carp::croak('resolve_service: this app declares no services')
        unless _nano_has_services($app);
    return $app->($SERVICE_RESOLVE_PROBE, $name);
}

sub _build_flat_routes {
    my ($collector) = @_;
    my %flat = %{ $collector->{named} };
    for my $m (@{ $collector->{nano_mounts} }) {
        for my $nm (keys %{ $m->{flat} }) {
            Carp::croak("Duplicate route name '$nm'") if exists $flat{$nm};
            $flat{$nm} = $m->{prefix} . $m->{flat}{$nm};
        }
    }
    return \%flat;
}

# Wrap $app in app-wide middleware, mirroring PAGI::App::Router's event-layer
# chain (coderef with a $next, or an object with ->wrap).
sub _wrap_with_middleware {
    my ($app, $mws) = @_;
    my $chain = $app;
    for my $mw (reverse @$mws) {
        my $next = $chain;
        if (ref($mw) eq 'CODE') {
            $chain = async sub {
                my ($scope, $receive, $send) = @_;
                await $mw->($scope, $receive, $send, async sub {
                    # Forward a transformed channel when the middleware passes
                    # one; otherwise continue with the inherited triple. Matches
                    # PAGI::App::Router so app-wide and route/group coderef
                    # middleware behave the same.
                    my ($s, $r, $sd) = @_ ? @_ : ($scope, $receive, $send);
                    await $next->($s, $r, $sd);
                });
            };
        }
        else {
            # PAGI::Middleware contract: wrap($app) returns the composed app.
            $chain = $mw->wrap($next);
        }
    }
    return $chain;
}

# The lifespan startup hook that eagerly instantiates every declared service,
# in declaration order. Wrapped in async sub (rather than run synchronously
# during app { }) so a builder's die becomes a failed Future that
# PAGI::Lifespan awaits inside its own eval, turning it into
# lifespan.startup.failed -- the worker fails at boot, not on a request.
sub _service_startup_hook {
    my ($registry, $services) = @_;
    return async sub { $registry->_build_all($services) };
}

# Inject the registry onto every request's scope (plain assignment, not //=,
# per the design: a mounted Nano app's own services must win for requests
# routed into it).
sub _wrap_with_services {
    my ($app, $registry) = @_;
    return sub {
        my ($scope, $receive, $send) = @_;
        $scope->{'pagi.nano.services'} = $registry if ref $scope eq 'HASH';
        return $app->($scope, $receive, $send);
    };
}

# --- HTTP verbs -------------------------------------------------------------

sub get    { _add_route('GET',    @_) }
sub post   { _add_route('POST',   @_) }
sub put    { _add_route('PUT',    @_) }
sub patch  { _add_route('PATCH',  @_) }
sub del    { _add_route('DELETE', @_) }

sub any {
    my ($path, @rest) = @_;
    my ($mw, $handler, $name) = _parse_route_args(@rest);
    my $wrapped = _wrap_http($handler, $path);
    $COLLECTOR->{router}->any($path, ($mw ? (_to_router_middleware($mw)) : ()), $wrapped);
    _register_name($name, $path) if defined $name;
}

sub _add_route {
    my ($method, $path, @rest) = @_;
    my ($mw, $handler, $name) = _parse_route_args(@rest);
    my $wrapped = _wrap_http($handler, $path);
    $COLLECTOR->{router}->route($method, $path, ($mw ? (_to_router_middleware($mw)) : ()), $wrapped);
    _register_name($name, $path) if defined $name;
}

# An imperative HTTP route (the escape hatch): the handler gets $c, owns its own
# response (no return-value coercion), matches any method, and can drop fully to
# raw PAGI via $c->scope / $c->receive / $c->send.
sub raw {
    my ($path, @rest) = @_;
    my ($mw, $handler, $name) = _parse_route_args(@rest);
    my $wrapped = _wrap_raw($handler, $path);
    $COLLECTOR->{router}->any($path, ($mw ? (_to_router_middleware($mw)) : ()), $wrapped);
    _register_name($name, $path) if defined $name;
}

# --- grouping, mounting, static --------------------------------------------

sub group {
    my ($prefix, @rest) = @_;
    my ($mw, $block) = _parse_route_args(@rest);
    # The router manages the prefix/middleware stack; our verbs register into the
    # same router during the block, so they are prefixed and branch-wrapped. We
    # track the prefix in parallel so named routes record their full path.
    push @{ $COLLECTOR->{prefix_stack} }, $prefix;
    $COLLECTOR->{router}->group($prefix, ($mw ? (_to_router_middleware($mw)) : ()), sub { $block->() });
    pop @{ $COLLECTOR->{prefix_stack} };
}

sub mount {
    my ($prefix, $app) = @_;
    # The outermost app owns lifecycle (the router never forwards lifespan
    # events into a mount, so a mounted app's own startup/shutdown never run --
    # see mount's POD); a mounted app that declared services would silently
    # never build them, so refuse it loudly instead. A service-less mounted
    # Nano app is fine: it has no registry of its own, so requests routed into
    # it simply see whatever the outermost app injected onto the scope.
    Carp::croak("mount '$prefix': a mounted Nano app cannot declare services -- "
        . 'the outermost app owns lifecycle (see "mount" in the PAGI::Nano POD)')
        if _nano_has_services($app);

    # Fold a mounted Nano app's named routes into this app's flat registry
    # (prefixed) so links resolve across the mount. We ask the app for its names
    # via the probe; non-Nano mounts (PSGI bridges, file servers) report none.
    if (my $flat = _nano_flat_routes($app)) {
        push @{ $COLLECTOR->{nano_mounts} }, { prefix => $prefix, flat => $flat };
    }
    $COLLECTOR->{router}->mount($prefix, $app);
}

sub static {
    my ($url, $dir) = @_;
    require PAGI::App::File;
    $COLLECTOR->{router}->mount($url, PAGI::App::File->new(root => $dir));
}

# --- middleware, lifecycle, 404 --------------------------------------------

sub enable {
    my ($spec, %args) = @_;
    push @{$COLLECTOR->{app_mw}}, _normalize_middleware($spec, %args);
}

sub startup  { push @{$COLLECTOR->{startup}},  $_[0] }
sub shutdown { push @{$COLLECTOR->{shutdown}}, $_[0] }

sub service {
    my ($name, $builder) = @_;
    Carp::croak("service '$name' declared outside an app { } block")
        unless $COLLECTOR;
    Carp::croak("Duplicate service '$name'")
        if grep { $_->[0] eq $name } @{$COLLECTOR->{services}};
    push @{$COLLECTOR->{services}}, [$name, $builder];
}

# Marks a service builder's returned coderef as a per-call maker: every
# $c->service access invokes it fresh, nothing is memoized. Without this a
# returned coderef is a per-request maker (memoized for the request instead).
sub factory {
    my ($cb) = @_;
    Carp::croak('factory: expected a coderef') unless ref $cb eq 'CODE';
    return bless $cb, 'PAGI::Nano::Marker::Factory';
}

sub not_found {
    my ($handler) = @_;
    my $http_handler = _wrap_http($handler, '');

    $COLLECTOR->{router}{not_found} = sub {
        my ($scope, $receive, $send) = @_;
        my $type = $scope->{type} // 'http';

        return $http_handler->($scope, $receive, $send)
            if $type eq 'http';

        Carp::croak("not_found cannot decline unsupported scope type '$type'")
            unless $type eq 'sse' || $type eq 'websocket';

        if ($type eq 'websocket'
                && !exists(($scope->{extensions} // {})->{'websocket.http.response'})) {
            return $send->({ type => 'websocket.close' });
        }

        my $prefix = $type eq 'sse'
            ? 'sse.http.response'
            : 'websocket.http.response';
        my $adapted_send = _translate_not_found_send(
            $send,
            $prefix,
            body_only_protocol => $type,
        );
        return $http_handler->($scope, $receive, $adapted_send);
    };
}

sub _translate_not_found_send {
    my ($send, $prefix, %opts) = @_;
    return sub {
        my ($event) = @_;
        my $type = $event->{type} // '';
        Carp::croak("not_found emitted unsupported event '$type'")
            unless $type eq 'http.response.start'
                || $type eq 'http.response.body';

        if ($opts{body_only_protocol} && $type eq 'http.response.body'
                && (exists $event->{file} || exists $event->{fh})) {
            Carp::croak("$opts{body_only_protocol} not_found responses support "
                . 'body bytes, not file/fh bodies');
        }

        my %translated = %$event;
        $translated{type} =~ s/^http\.response/$prefix/;
        return $send->(\%translated);
    };
}

# --- WebSocket / SSE (imperative; not coerced) ------------------------------

sub websocket {
    my ($path, @rest) = @_;
    my ($mw, $handler, $name) = _parse_route_args(@rest);
    my $wrapped = _wrap_socket($handler, $path);
    $COLLECTOR->{router}->websocket($path, ($mw ? (_to_router_middleware($mw)) : ()), $wrapped);
    _register_name($name, $path) if defined $name;
}

sub sse {
    my ($path, @rest) = @_;
    my ($mw, $handler, $name) = _parse_route_args(@rest);
    my $wrapped = _wrap_socket($handler, $path);
    $COLLECTOR->{router}->sse($path, ($mw ? (_to_router_middleware($mw)) : ()), $wrapped);
    _register_name($name, $path) if defined $name;
}

sub _register_name {
    my ($name, $path) = @_;
    my $full = join('', @{ $COLLECTOR->{prefix_stack} }, $path);
    Carp::croak("Duplicate route name '$name'")
        if exists $COLLECTOR->{named}{$name};
    $COLLECTOR->{named}{$name} = $full;
}

# --- handler wrapping -------------------------------------------------------

# Extract a route's :placeholder names in path order so they can be passed to the
# handler signature after $c. Supports :name, {name}, {name:regex}, and *splat.
sub _placeholder_names {
    my ($path) = @_;
    my @names;
    while ($path =~ /\{(\w+)(?::[^}]+)?\}|\*(\w+)|:(\w+)/g) {
        push @names, defined $1 ? $1 : defined $2 ? $2 : $3;
    }
    return @names;
}

# A route declared without a handler coderef is a loud build-time error (caught
# while app { } runs) rather than a "Not a CODE reference" 500 at first request.
sub _assert_handler {
    my ($handler, $path) = @_;
    Carp::croak("route '$path' is missing a handler (expected a coderef)")
        unless ref $handler eq 'CODE';
}

# Error handling uses Future combinators rather than try/catch so the core runs
# on Perl back to 5.18. A die in the ->then callback (e.g. an uncoercible return)
# becomes a failed Future and is handled by ->else.
sub _wrap_http {
    my ($handler, $path) = @_;
    _assert_handler($handler, $path);
    my @names = _placeholder_names($path);
    return sub {
        my ($scope, $receive, $send) = @_;
        my $c = PAGI::Nano::Context::HTTP->new($scope, $receive, $send);
        my @params = map { $scope->{path_params}{$_} } @names;

        return _invoke_handler($handler, $c, \@params)->then(sub {
            my ($res) = @_;
            return $c->respond(_coerce($res));
        })->else(sub {
            my ($err) = @_;
            # The "featherweight die-a-respond-able" escape hatch: a thrown
            # respond-able value is sent as-is; anything else propagates and
            # becomes a 500 (rendered by enable 'ErrorHandler' or the server).
            return $c->respond($err)
                if Scalar::Util::blessed($err) && $err->can('respond');
            return Future->fail($err);
        });
    };
}

# Imperative handler wrapping: build the context, pass the ordered path params,
# and return the handler's future as-is — no return-value coercion. Shared by the
# WebSocket/SSE verbs and the raw escape hatch; they differ only in which context
# they vend.
sub _wrap_imperative {
    my ($handler, $path, $make_context) = @_;
    _assert_handler($handler, $path);
    my @names = _placeholder_names($path);
    return sub {
        my ($scope, $receive, $send) = @_;
        my $c = $make_context->($scope, $receive, $send);
        my @params = map { $scope->{path_params}{$_} } @names;
        return _invoke_handler($handler, $c, \@params);
    };
}

sub _wrap_socket {
    my ($handler, $path) = @_;
    return _wrap_imperative($handler, $path, \&_socket_context);
}

sub _wrap_raw {
    my ($handler, $path) = @_;
    return _wrap_imperative($handler, $path, sub {
        PAGI::Nano::Context::HTTP->new(@_);
    });
}

# Vend the Nano WebSocket/SSE context (which carries uri_for) by scope type,
# falling back to the stock polymorphic context for anything else.
sub _socket_context {
    my ($scope, $receive, $send) = @_;
    my $type = $scope->{type} // '';
    return PAGI::Nano::Context::WebSocket->new($scope, $receive, $send)
        if $type eq 'websocket';
    return PAGI::Nano::Context::SSE->new($scope, $receive, $send)
        if $type eq 'sse';
    return PAGI::Context->new($scope, $receive, $send);
}

# Call a handler and normalize its result to a Future, capturing a synchronous
# die from a non-async handler as a failed Future.
sub _invoke_handler {
    my ($handler, $c, $params) = @_;
    my $res = eval { $handler->($c, @$params) };
    return Future->fail($@) if $@;
    return $res if Scalar::Util::blessed($res) && $res->isa('Future');
    return Future->done($res);
}

# JSON encoder for coerced bodies. convert_blessed lets any object with a
# TO_JSON method serialize itself (e.g. a domain value nested in the response).
my $JSON = JSON::MaybeXS->new(utf8 => 1, canonical => 1, convert_blessed => 1);

# The coercion table.
sub _coerce {
    my ($res) = @_;
    if (Scalar::Util::blessed($res)) {
        return $res if $res->can('respond');    # a PAGI::Response (sent as-is)
        Carp::croak('PAGI::Nano handler returned an uncoercible '
            . ref($res) . ' object');
    }

    my $ref = ref $res;
    if ($ref eq 'HASH' || $ref eq 'ARRAY') {
        return PAGI::Response->send_raw(
            $JSON->encode($res),
            content_type => 'application/json; charset=utf-8',
        );
    }

    Carp::croak("PAGI::Nano handler returned an uncoercible $ref reference")
        if $ref;

    Carp::croak('PAGI::Nano handler returned no response '
        . '(did the handler forget to return a value?)')
        unless defined $res;

    return PAGI::Response->text($res);
}

# --- middleware normalization ----------------------------------------------

# Turn a middleware spec (name string, instance, or coderef) into something the
# router/chain accepts: a coderef ($scope,$receive,$send,$next) or an object
# with ->wrap. Names are resolved the way `enable` resolves them.
sub _normalize_middleware {
    my ($spec, %args) = @_;
    return $spec if ref($spec) eq 'CODE';
    return $spec if Scalar::Util::blessed($spec) && $spec->can('wrap');

    Carp::croak('Invalid middleware: expected a name, instance, or coderef')
        if ref $spec;

    # A leading ^ escapes the default prefix: use the rest of the name verbatim.
    my $class = $spec =~ /^\^/ ? substr($spec, 1) : "PAGI::Middleware::$spec";
    my $file = ($class =~ s{::}{/}gr) . '.pm';
    require $file;
    return $class->new(%args);
}

# Adapt middleware for PAGI::App::Router, whose contract is a factory coderef
# ($factory->($app) returns the wrapped app) or an object with ->wrap. Nano's
# coderef middleware shape is ($scope, $receive, $send, $next); wrap each in a
# factory preserving those semantics (including transformed-channel forwarding).
sub _to_router_middleware {
    my ($mws) = @_;
    return [ map {
        my $mw = $_;
        ref($mw) eq 'CODE'
            ? sub {
                my ($app) = @_;
                return async sub {
                    my ($scope, $receive, $send) = @_;
                    await $mw->($scope, $receive, $send, async sub {
                        my ($s, $r, $sd) = @_ ? @_ : ($scope, $receive, $send);
                        await $app->($s, $r, $sd);
                    });
                };
            }
            : $mw
    } @$mws ];
}

sub _normalize_middleware_list {
    my ($specs) = @_;
    return [ map { _normalize_middleware($_) } @$specs ];
}

# Parse the arguments between a verb's path and its handler: an arrayref or a
# middleware() marker contributes middleware; a name() marker names the route;
# the bare trailing coderef is the handler. Markers may appear in any order.
# Returns (\@normalized_middleware | undef, $handler, $name | undef).
sub _parse_route_args {
    my @args = @_;
    my ($handler, $name, @mw);
    for my $arg (@args) {
        my $ref = ref $arg;
        if ($ref eq 'CODE') {
            $handler = $arg;
        }
        elsif ($ref eq 'ARRAY') {
            push @mw, @$arg;
        }
        elsif (Scalar::Util::blessed($arg)
            && $arg->isa('PAGI::Nano::Marker::Middleware')) {
            push @mw, @{ $arg->{list} };
        }
        elsif (Scalar::Util::blessed($arg)
            && $arg->isa('PAGI::Nano::Marker::Name')) {
            $name = $arg->{name};
        }
        else {
            Carp::croak('Unexpected route argument: '
                . (defined $arg ? $arg : 'undef'));
        }
    }
    my $mw = @mw ? _normalize_middleware_list(\@mw) : undef;
    return ($mw, $handler, $name);
}

1;

=encoding utf8

=head1 NAME

PAGI::Nano - A compact micro-framework front door over PAGI-Tools

=head1 SYNOPSIS

    use v5.40;
    use experimental 'signatures';
    use PAGI::Nano;

    my $app = app {
        startup  async sub ($state) { $state->{tasks} = [] };
        shutdown async sub ($state) { warn "served " . @{$state->{tasks}} . " tasks\n" };

        enable 'GZip';
        static '/assets' => 'public/';

        get '/'       => sub ($c) { 'PAGI::Nano' };               # String   -> text/plain
        any '/health' => sub ($c) { { ok => 1 } };               # hashref  -> JSON

        group '/api' => ['RateLimit'] => sub {
            get  '/tasks'     => sub ($c)      { $c->state->{tasks} };
            get  '/tasks/:id' => sub ($c, $id) {
                $c->state->{tasks}[$id - 1] // $c->json({ error => 'not found' }, status => 404);
            };
            post '/tasks'     => async sub ($c) {
                my $attrs = await $c->params->required(
                    'title', +{ tags => [] },
                    sub ($c, $missing) { $c->json({ error => 'missing', fields => $missing }, status => 400) },
                );
                my $tasks = $c->state->{tasks};
                push @$tasks, { id => @$tasks + 1, %$attrs };
                $c->json($tasks->[-1], status => 201);
            };
        };

        sse '/events' => async sub ($c) {
            my $s = $c->sse;
            for my $n (1 .. 5) { await $s->send("tick $n") }
        };

        not_found sub ($c) { $c->json({ error => 'no such route' }, status => 404) };
    };

    $app;   # run: pagi-server app.pl

=head1 DESCRIPTION

C<PAGI::Nano> is a compact micro-framework for demos and small apps (roughly
under 20 endpoints). "Nano" means I<compact>, not I<few features>: routing,
middleware, lifecycle, static files, streaming, WebSocket, SSE, and request
shaping are all in scope. The win is that a whole small app fits on one screen
and reads top-to-bottom.

Three principles shape it:

=over 4

=item * B<The DSL produces a value, not global state.> C<app { ... }> runs a
block-scoped collector (the same C<local>-scoped technique
L<PAGI::Middleware::Builder>'s C<builder { }> uses) and I<returns> an assembled
PAGI app. The result is composable (C<mount> it), nestable, testable, and
many-per-process.

=item * B<No silo, no cliff.> The DSL is thin sugar over the exact PAGI objects
you would use by hand — L<PAGI::Context>, L<PAGI::Response>,
L<PAGI::App::Router>, the builder, L<PAGI::Lifespan>, L<PAGI::App::File>. You can
drop to raw PAGI mid-app, and a Nano app already I<is> a PAGI app.

=item * B<Anti-magic.> The only convention is return-value coercion, which is
local and visible at the call site. C<@INC> is never touched.

=back

Strong-parameters (C<< $c->params >>) shape input; validation and persistence
are out of scope (use Valiant downstream and your own model).

=head1 EXPORTS

All of the following are exported by default:
C<app>, C<get>, C<post>, C<put>, C<patch>, C<del>, C<any>, C<raw>, C<group>,
C<mount>, C<enable>, C<startup>, C<shutdown>, C<static>, C<not_found>,
C<websocket>, C<sse>, C<name>, C<middleware>, C<service>, C<factory>.

=head1 THE COLLECTOR

=head2 app

    my $app = app { ... };

Runs the block with a fresh, dynamically-scoped collector, registering whatever
the verbs declare, then assembles and returns the composed PAGI app: the router,
wrapped in any C<enable>'d middleware, wrapped in L<PAGI::Lifespan> if
C<startup>/C<shutdown> were declared. No package globals; nesting is supported.

=head1 ROUTING

=head2 get / post / put / patch / del

    get  '/path'        => sub ($c) { ... };
    post '/path'        => [\@middleware] => sub ($c) { ... };
    del  '/thing/:id'   => sub ($c, $id) { ... };

Each registers a route for the named HTTP method. C<del> is spelled without an
C<e> so it does not shadow Perl's C<delete>. An optional arrayref of middleware
may precede the handler.

A route's C<:placeholders> become the handler's parameters, in path order, after
C<$c>: C<< get '/u/:uid/p/:pid' => sub ($c, $uid, $pid) { ... } >>. The supported
placeholder forms are C<:name>, C<{name}>, C<{name:regex}>, and C<*splat>.
C<< $c->path_param('name') >> remains available.

Per-route attributes are given as markers in the same arrow chain, before the
handler, in any order: L</name> names the route for link generation, and
L</middleware> (or the C<[...]> shorthand) scopes middleware to it:

    get '/users/:id' => name('user') => middleware('Auth') => sub ($c, $id) { ... };
    get '/users/:id' => name('user') => ['Auth']          => sub ($c, $id) { ... };

=head2 any

    any '/health' => sub ($c) { ... };

Like the verbs above, but matches every HTTP method.

=head2 raw

    raw '/stream' => async sub ($c) {
        await $c->respond($c->json({ ok => 1 }));   # send your own response
    };

The imperative escape hatch. Unlike C<get>/C<post>/etc., a C<raw> handler is
B<not> coerced: it receives C<$c> (and any path placeholders) and is responsible
for sending its own response — via C<< $c->respond >>, C<< $c->response->stream >>,
or the raw protocol. Its return value is ignored. C<raw> matches every method
(the handler dispatches on C<< $c->method >> if it cares).

This is where you drop to raw PAGI mid-app: C<< $c->scope >>, C<< $c->receive >>,
and C<< $c->send >> give the underlying C<($scope, $receive, $send)>, so a C<raw>
handler can do anything a hand-written PAGI app can — emit custom send events for
a middleware to render, stream a bespoke protocol, and so on — while still getting
path-parameter and middleware sugar. Because it is uncoerced, B<a raw handler that
never sends a response leaves the request hanging>; that is the handler's
responsibility.

=head2 group

    group '/api' => [\@middleware] => sub { ...nested verbs... };

Registers the nested verbs under a shared path prefix and (optional)
branch-shared middleware. Groups nest.

=head2 mount

    mount '/admin' => $app_or_coercible;

Nests any PAGI app (coerced via C<to_app>) under a prefix — another Nano app, a
L<PAGI::Endpoint::Router>, or any coderef app.

The router does not forward lifespan events to mounted apps, so a mounted Nano
app's own C<startup>/C<shutdown> do not run; the outermost app owns lifecycle and
mounted children share its C<state>. Write mountable apps to initialize their
slice of state defensively. For the same reason, C<mount> croaks if the app
being mounted declared any L</SERVICES> — a service-less mounted app is fine,
and transparently shares the outermost app's services.

=head1 RESPONSES AND COERCION

A handler returns a value, which Nano coerces:

=over 4

=item * a L<PAGI::Response> (anything that C<can('respond')>) — sent as-is.

=item * a hashref or arrayref — C<application/json> (with C<convert_blessed>, so
nested objects with a C<TO_JSON> method serialize themselves).

=item * a defined non-ref scalar — C<text/plain>.

=item * C<undef> / a bare C<return;> — a B<loud error> (becomes a 500): this
catches the forgot-to-return bug rather than sending a silent empty 200.

=item * any other reference — an error.

=back

A handler that uses C<await> (for C<< $c->params >>, streaming, etc.) must be
declared C<async sub>, which requires C<use Future::AsyncAwait> in the file
alongside C<use PAGI::Nano>. For explicit control, the inherited context sugar
C<< $c->json($data, %opts) >>, C<< $c->text >>, C<< $c->html >>,
C<< $c->redirect >> returns L<PAGI::Response> values.

A thrown respond-able value is sent as-is (the basis of C<required>'s on-missing
callback); any other exception propagates and becomes a 500, which
C<enable 'ErrorHandler'> can render.

=head1 MIDDLEWARE

=head2 enable

    enable 'GZip';
    enable 'Session', secret => '...';

Adds app-wide, event-layer middleware. A bare name (C<'GZip'>) resolves to
C<PAGI::Middleware::GZip>; a leading C<^> (C<'^My::MW'>) escapes the prefix.
Instances and coderefs (with the C<< ($scope, $receive, $send, $next) >>
signature) are also accepted. Route- and group-scoped middleware use the
C<[\@middleware]> form and are normalized the same way.

=head1 NAMED ROUTES AND LINKS

=head2 name

    get '/users/:id' => name('user') => sub ($c, $id) { ... };

A marker that names the route. Names form a single flat namespace across the
whole app (including mounted sub-apps); a duplicate name is a loud error.

=head2 middleware

    get '/x' => middleware('Auth', $coderef) => sub ($c) { ... };

A marker that scopes the given middleware to the route (the C<[...]> arrayref is
the everyday shorthand). Each element is a middleware spec — a name, an instance,
or a coderef — resolved the same way L</enable> resolves a name. Unlike
C<enable>, the route forms take no per-name constructor arguments: every element
is its own spec, so to configure a name-based middleware, pre-instantiate it
(C<< [ PAGI::Middleware::Session->new(secret => '...') ] >>) and pass the
instance.

=head2 C<< $c->uri_for >>

    $c->uri_for('user', { id => 5 });                  # /users/5
    $c->uri_for('user', { id => 5 }, { tab => 'a' });  # /users/5?tab=a

Builds the URL for a named route, substituting path placeholders and appending
an optional query string. Because Nano injects one flat name registry onto the
request scope, C<uri_for> resolves B<any> name from B<anywhere> — including
across a C<mount> in both directions: a mounted app can link to a name defined
in its parent, and the parent can link to a name defined in the mount (paths are
returned with the mount prefix applied). C<uri_for> is available on the context
for every protocol — HTTP, WebSocket, and SSE handlers alike (see
L<PAGI::Nano::Context>).

=head1 LIFECYCLE AND SHARED STATE

=head2 startup / shutdown

    startup  async sub ($state) { ... };
    shutdown async sub ($state) { ... };

Sugar over L<PAGI::Lifespan>. C<$state> is the shared, app-lifetime state
hashref; handlers read it via C<< $c->state >>.

=head1 SERVICES

=head2 service / factory

    service schema => sub ($app) {
        return $schema;                              # app-scoped singleton
    };

    service params => sub ($app) {
        return sub ($ctx) {                           # per-request maker
            return Params->new($ctx->params);
        };
    };

    service stamp => sub ($app) {
        return factory sub ($ctx) {                   # per-call maker
            return Stamp->new;
        };
    };

A tiny three-scope registry. C<service NAME =E<gt> BUILDER> declares a
service; C<< $c->service(NAME) >> resolves it at request time, on every
context flavor (HTTP, WebSocket, and SSE alike). The scope is chosen by what
the builder I<returns>, not by any option:

=over 4

=item * a plain value (including any blessed object, other than a C<factory>
marker below) — an B<app-scoped singleton>. Every C<< $c->service >> access,
on every request, returns this same value.

=item * an unblessed coderef — a B<per-request maker>. The first
C<< $c->service >> access in a request calls it with the context and memoizes
the result for the rest of that request (for a WebSocket or SSE context,
"request" means that connection); later accesses in the same
request/connection return the memoized value.

=item * C<< factory sub { ... } >> — a B<per-call maker>. Every access calls
it with the context; nothing is memoized, so every C<< $c->service >> call
gets a fresh object.

=back

Builders run B<eagerly, once per worker, in declaration order>, at lifespan
startup — registered before any user C<startup> hook (see L</startup /
shutdown>). A builder that dies fails lifespan startup, so a misconfigured
service stops the worker at boot rather than surfacing on a customer's first
request. Builders are B<synchronous>: a builder written as C<async sub>
returns a Future, and returning a Future croaks at startup — for deferred
construction return a per-request maker (a plain coderef) or a C<factory>
maker instead.

Builders B<compose>: each builder receives the registry itself (C<$app> in
the examples above), and C<< $app->service(NAME) >> returns an
already-built service, letting a later service incorporate an earlier one.
Because building is eager and ordered, asking for a service declared later in
the same C<app { }> block — or not declared at all — croaks, naming the
service: services can only depend on what has already been built.

Since a plain returned coderef always means "per-request maker", a service
that itself needs to hand out a fixed callback (not build one per request)
uses the per-request-maker shape as an escape hatch, returning the same
closure every time:

    service on_tick => sub ($app) {
        my $callback = sub { ... };
        return sub ($ctx) { return $callback };
    };

There is no teardown pairing in v1: a service that owns a resource needing
cleanup should register its own C<shutdown> hook. There are also no generated
accessors — always C<< $c->service('schema') >>, never C<< $c->schema >>.

B<Services and C<mount>: the outermost app owns lifecycle.> Just as a mounted
Nano app's own C<startup>/C<shutdown> never run (see L</mount> — the router
never forwards lifespan events into a mount), a mounted Nano app cannot
declare services at all: C<mount> croaks immediately if the app being mounted
declared any, since their builders would never get a chance to run. A mounted
Nano app that declares no services of its own is unaffected — it has no
registry, so C<< $c->service >> inside it simply resolves against whatever the
outermost app injected onto the scope, the same instances the rest of the app
sees. If lifespan forwarding to mounted apps is ever added, per-mount services
can be revisited.

=head2 resolve_service

    my $app = app { service schema => sub { $dbh } };
    my $client = PAGI::Test::Client->new(app => $app, lifespan => 1);
    $client->start;                                    # runs the builders
    my $schema = PAGI::Nano::resolve_service($app, 'schema');

A test seam. C<< $c->service >> is only reachable from inside a request handler,
so a test that wants to assert on an app-scoped service — or hand it to code
under test — otherwise has to route a request just to reach it, or reconstruct
the service by hand. C<resolve_service> (not exported; call it fully qualified)
reaches the service directly: given the assembled app coderef and a name, it
returns the built value, B<after lifespan startup has run> (drive it with
C<< PAGI::Test::Client->start >>, or a lifespan C<startup> event by hand). The
registry the startup hook builds is retained on the app coderef, so no request
is involved.

It resolves B<app-scoped> services (a plain value or a blessed non-C<factory>
object). A per-request maker or a C<factory> is constructed against a request
context, which does not exist here, so for those C<resolve_service> returns the
raw maker coderef / factory marker rather than a per-request instance — a test
needing the per-request value must drive a real request. Resolving an unknown
name croaks (naming it), as does calling it on an app that declared no services.

=head1 STATIC FILES AND CUSTOM 404

=head2 static

    static '/assets' => 'public/';

Serves files under C<public/> at C</assets/*> (wraps L<PAGI::App::File>).

=head2 not_found

    not_found sub ($c) { ... };

Sets the router's not-found handler; it is wrapped and coerced like any other
HTTP handler. Write the handler as an ordinary HTTP-shaped Nano response.
For an unmatched HTTP request its response events pass through unchanged; for
an SSE scope Nano translates them to C<sse.http.response.*> decline events.
Buffered and streamed byte bodies work for translated responses, but
file-backed C<file>/C<fh> body events are not part of the SSE or WebSocket
decline event families and croak loudly. Return bytes from the handler instead
of C<send_file>.

An unmatched WebSocket can carry the custom status, headers, and body only when
the server advertises the C<websocket.http.response> extension. Nano then emits
C<websocket.http.response.*> events.

Without the extension Nano does not invoke the custom handler. It sends a
pre-accept C<websocket.close>, asking the server to provide the portable,
body-less 403 denial response.

=head1 STREAMING, WEBSOCKET, SSE

WebSocket and SSE handlers are imperative: like L</raw>, they own the connection,
return nothing, and are B<not> coerced. Both take the same
C<< PATH => [\@middleware] => $handler >> shape as the HTTP verbs (middleware and
L</name> markers are optional and may appear in any order).

=head2 websocket

    websocket '/echo' => async sub ($c) {
        my $ws = $c->websocket;
        await $ws->accept;
        await $ws->each_json(async sub ($msg) { await $ws->send_json({ echo => $msg }) });
    };

Registers a WebSocket route. The handler gets the L<PAGI::Nano::Context::WebSocket>
context (C<< $c->websocket >> for the socket API, C<< $c->uri_for >> for links).

=head2 sse

    sse '/events' => async sub ($c) {
        my $s = $c->sse;
        for my $n (1 .. 5) { await $s->send("tick $n") }
    };

Registers a Server-Sent Events route. The handler gets the
L<PAGI::Nano::Context::SSE> context; C<< $c->send >> is the C<sse.send>
convenience, and C<< $c->raw_send >> reaches the raw channel for custom event
types.

Streaming uses the response writer and request body stream:

    post '/upper' => async sub ($c) {
        my $in = $c->req->body_stream;
        $c->response->stream(async sub ($w) {
            while (defined(my $chunk = await $in->next_chunk)) { await $w->write(uc $chunk) }
            await $w->close;
        });
    };

=head1 STRONG PARAMETERS

C<< $c->params >> returns a request-bound L<PAGI::StructuredParameters::Request>
selecting the source by content-type. The terminal C<permitted> (filter to a
whitelist) and C<required> (whitelist plus a mandatory on-missing callback) are
awaited, because reading a request body is asynchronous. The chainable
C<namespace> (scope the rules to a key prefix) and C<flatten_array_value>
(control array flattening for form sources) shape parsing before them. See
L<PAGI::Nano::Context::HTTP> and L<PAGI::StructuredParameters> for the full rule
grammar.

=head1 RUNNING

A Nano app is an ordinary PAGI app (a coderef). Run a single file with
C<pagi-server app.pl>, where the file's last expression is the app. For a real
app, use a modulino at C<lib/MyApp.pm> whose C<to_app> returns C<app { ... }>,
and run C<pagi-server -Ilib lib/MyApp.pm>. Nano never touches C<@INC>.

=head1 SEE ALSO

L<PAGI::Tools>, L<PAGI::StructuredParameters>, L<PAGI::Nano::Context::HTTP>,
L<PAGI::App::Router>, L<PAGI::Lifespan>, L<PAGI::Nano::ServiceRegistry>.

=head1 AUTHOR

John Napiorkowski C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2026, John Napiorkowski. This library is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
