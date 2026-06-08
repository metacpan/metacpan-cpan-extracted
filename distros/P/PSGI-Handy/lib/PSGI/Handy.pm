package PSGI::Handy;
######################################################################
#
# PSGI::Handy - a tiny dependency-free PSGI web framework for Perl 5.005_03+
#
# A single-file micro framework: a router, request/response objects and
# a per-request context are wired into one PSGI-subset application via
# to_app(). Templates (HP::Handy) and a database handle (DB::Handy) are
# injected, keeping this layer decoupled and testable.
#
# All component classes (PSGI::Handy::Response, ::Request, ::Router and
# ::Context) live in THIS file; there are no separate PSGI/Handy/*.pm
# files. They are laid out below in dependency order. This module loads
# nothing outside the Perl core.
#
# 5.005_03 safe: no //, say, state, our, 3-arg open, lexical FH, and no
# named regex captures anywhere in the distribution.
#
######################################################################
use 5.00503;    # Universal Consensus 1998 for primetools
                # Perl 5.005_03 compatibility for historical toolchains
# use 5.008001; # Lancaster Consensus 2013 for toolchains

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use vars qw($VERSION);
$VERSION = '0.01';
$VERSION = $VERSION;
# $VERSION self-assignment suppresses "used only once" warning under strict.
use Carp;
# croak() is called as Carp::croak() throughout so that one "use Carp"
# serves every package in this single file (a bareword croak would only
# be imported into the package current at the point of "use Carp").

######################################################################
# PSGI::Handy::Response - tiny PSGI response builder
#
# Builds the PSGI three-element response [ $status, \@headers, \@body ]
# with an incremental, chainable API plus class shortcuts for the common
# response types (text, html, json, redirect).
######################################################################
package PSGI::Handy::Response;

# Byte-accurate length for Content-Length. The bytes pragma does not exist
# on Perl 5.005_03 (and there are no wide-character strings there), so we
# probe for it once and call bytes::length() as a function (no lexical
# pragma needed) on Perls that have it.
my $HAS_BYTES;
BEGIN { $HAS_BYTES = eval { require bytes; 1 } ? 1 : 0; }

sub _byte_length {
    my ($s) = @_;
    return 0 unless defined $s;
    return $HAS_BYTES ? bytes::length($s) : length($s);
}

# Strip CR/LF from header keys and values to prevent header injection.
sub _crlf_safe {
    my ($s) = @_;
    return $s unless defined $s;
    $s =~ s/[\r\n]//g;
    return $s;
}

# --------------------------------------------------------------------
# new(%args) - status => 200, type => 'text/html; charset=utf-8',
#              body => $scalar_or_arrayref
# --------------------------------------------------------------------
sub new {
    my ($class, %args) = @_;
    my $self = {
        status  => (defined $args{status} ? $args{status} : 200),
        headers => [],                       # list of [ key, value ]
        body    => _body_to_array($args{body}),
    };
    bless $self, $class;
    $self->set_header('Content-Type', $args{type}) if defined $args{type};
    return $self;
}

# --- class shortcuts (return a Response object) ---------------------
sub html {
    my ($class, $str, $code) = @_;
    return $class->new(
        status => (defined $code ? $code : 200),
        type   => 'text/html; charset=utf-8',
        body   => $str,
    );
}

sub text {
    my ($class, $str, $code) = @_;
    return $class->new(
        status => (defined $code ? $code : 200),
        type   => 'text/plain; charset=utf-8',
        body   => $str,
    );
}

# JSON string must already be encoded by the caller (e.g. via mb::JSON).
sub json {
    my ($class, $str, $code) = @_;
    !ref($str)
        or Carp::croak "json: body must be a pre-encoded JSON string, not a reference";
    return $class->new(
        status => (defined $code ? $code : 200),
        type   => 'application/json',
        body   => $str,
    );
}

sub redirect {
    my ($class, $location, $code) = @_;
    defined $location or Carp::croak "redirect: location is required";
    my $self = $class->new(
        status => (defined $code ? $code : 302),
        type   => 'text/plain; charset=utf-8',
        body   => "Redirect to $location",
    );
    $self->set_header('Location', $location);
    return $self;
}

# --- accessors / mutators (mutators return $self for chaining) ------
sub status {
    my $self = shift;
    return $self->{status};
}

sub set_status {
    my ($self, $code) = @_;
    $self->{status} = $code;
    return $self;
}

sub body {
    my $self = shift;
    return $self->{body};
}

sub set_body {
    my ($self, $content) = @_;
    $self->{body} = _body_to_array($content);
    return $self;
}

# Append a header (allows duplicates, e.g. several Set-Cookie lines).
sub header {
    my ($self, $key, $value) = @_;
    push @{ $self->{headers} }, [ _crlf_safe($key), _crlf_safe($value) ];
    return $self;
}

# Replace any existing header(s) of this name, then set it.
sub set_header {
    my ($self, $key, $value) = @_;
    $key   = _crlf_safe($key);
    $value = _crlf_safe($value);
    my $lc = lc($key);
    my @kept = grep { lc($_->[0]) ne $lc } @{ $self->{headers} };
    push @kept, [ $key, $value ];
    $self->{headers} = [ @kept ];
    return $self;
}

sub remove_header {
    my ($self, $key) = @_;
    my $lc = lc($key);
    $self->{headers} = [ grep { lc($_->[0]) ne $lc } @{ $self->{headers} } ];
    return $self;
}

sub content_type {
    my ($self, $type) = @_;
    return $self->set_header('Content-Type', $type);
}

# Add a Set-Cookie header. %opts: path, domain, max_age, expires,
# secure (bool), httponly (bool).
sub cookie {
    my ($self, $name, $value, %opts) = @_;
    defined $name or Carp::croak "cookie: name is required";
    $value = '' unless defined $value;
    my $c = $name . '=' . _cookie_encode($value);
    $c .= '; Path='    . $opts{path}    if defined $opts{path};
    $c .= '; Domain='  . $opts{domain}  if defined $opts{domain};
    $c .= '; Max-Age=' . $opts{max_age} if defined $opts{max_age};
    $c .= '; Expires=' . $opts{expires} if defined $opts{expires};
    $c .= '; Secure'   if $opts{secure};
    $c .= '; HttpOnly' if $opts{httponly};
    return $self->header('Set-Cookie', $c);
}

# --------------------------------------------------------------------
# finalize - produce the PSGI array [ $status, \@flat_headers, \@body ]
# Content-Length is computed from the body unless already present.
# --------------------------------------------------------------------
sub finalize {
    my $self = shift;
    my @flat;
    my $has_length = 0;
    my $pair;
    for $pair (@{ $self->{headers} }) {
        push @flat, $pair->[0], $pair->[1];
        $has_length = 1 if lc($pair->[0]) eq 'content-length';
    }
    unless ($has_length) {
        my $len = 0;
        my $chunk;
        for $chunk (@{ $self->{body} }) {
            $len += _byte_length($chunk);
        }
        push @flat, 'Content-Length', $len;
    }
    return [ $self->{status}, \@flat, [ @{ $self->{body} } ] ];
}

# --- internals ------------------------------------------------------
sub _body_to_array {
    my ($content) = @_;
    return []                  unless defined $content;
    return [ @$content ]       if ref($content) eq 'ARRAY';
    return [ $content ];
}

sub _cookie_encode {
    my ($s) = @_;
    $s =~ s/([^A-Za-z0-9_\-.~])/sprintf('%%%02X', ord($1))/eg;
    return $s;
}

######################################################################
# PSGI::Handy::Request - tiny PSGI env wrapper
#
# Wraps a PSGI %env and exposes method, path, query/body parameters
# (merged), headers, cookies and the raw body. Query- and body-parameter
# parsing and percent-decoding are implemented here in pure Perl.
######################################################################
package PSGI::Handy::Request;

# --------------------------------------------------------------------
# new($env) - wrap a PSGI environment hash reference
# --------------------------------------------------------------------
sub new {
    my ($class, $env) = @_;
    ref($env) eq 'HASH' or Carp::croak "new: a PSGI env hash reference is required";
    my $self = { env => $env };
    return bless $self, $class;
}

# --- request line -----------------------------------------------------
sub method {
    my $self = shift;
    my $m = $self->{env}{REQUEST_METHOD};
    return defined $m ? $m : '';
}

sub path {
    my $self = shift;
    my $p = $self->{env}{PATH_INFO};
    return defined $p ? $p : '';
}

sub query_string {
    my $self = shift;
    my $q = $self->{env}{QUERY_STRING};
    return defined $q ? $q : '';
}

sub content_type {
    my $self = shift;
    my $t = $self->{env}{CONTENT_TYPE};
    return defined $t ? $t : '';
}

sub content_length {
    my $self = shift;
    my $l = $self->{env}{CONTENT_LENGTH};
    return (defined $l && $l ne '') ? int($l) : 0;
}

sub env {
    my $self = shift;
    return $self->{env};
}

# --- headers ----------------------------------------------------------
# Accepts 'Content-Type', 'content_type', 'X-Forwarded-For', etc.
sub header {
    my ($self, $name) = @_;
    return undef unless defined $name;
    my $key = uc($name);
    $key =~ s/-/_/g;
    if ($key eq 'CONTENT_TYPE' || $key eq 'CONTENT_LENGTH') {
        return $self->{env}{$key};
    }
    return $self->{env}{'HTTP_' . $key};
}

# --- raw body (read once from psgi.input, then cached) ---------------
sub body {
    my $self = shift;
    return $self->{_body} if exists $self->{_body};
    my $buf = '';
    my $len = $self->content_length;
    my $input = $self->{env}{'psgi.input'};
    if ($len > 0 && $input) {
        # psgi.input->read may return fewer bytes than requested, so loop
        # until CONTENT_LENGTH bytes are read or the stream ends.
        my $chunk;
        my $got = 0;
        while ($got < $len) {
            my $n = $input->read($chunk, $len - $got);
            last unless $n;        # EOF or error: keep what we have
            $buf .= $chunk;
            $got += $n;
        }
    }
    $self->{_body} = $buf;
    return $buf;
}

# --- parameters (query string merged with urlencoded body) -----------
sub param {
    my ($self, $name) = @_;
    $self->_build_params;
    return undef unless defined $name;
    my $v = $self->{_params}{$name};
    return undef unless $v;
    return $v->[0];
}

sub param_all {
    my ($self, $name) = @_;
    $self->_build_params;
    return () unless defined $name;
    my $v = $self->{_params}{$name};
    return () unless $v;
    return @$v;
}

sub param_names {
    my $self = shift;
    $self->_build_params;
    return keys %{ $self->{_params} };
}

# Flat hash reference: name => first value.
sub params {
    my $self = shift;
    $self->_build_params;
    my %flat;
    my $k;
    for $k (keys %{ $self->{_params} }) {
        $flat{$k} = $self->{_params}{$k}[0];
    }
    return { %flat };
}

# --- cookies ----------------------------------------------------------
sub cookie {
    my ($self, $name) = @_;
    $self->_parse_cookies;
    return undef unless defined $name;
    return $self->{_cookies}{$name};
}

sub cookies {
    my $self = shift;
    $self->_parse_cookies;
    my %copy = %{ $self->{_cookies} };
    return { %copy };
}

# --- internals --------------------------------------------------------
sub _build_params {
    my $self = shift;
    return if $self->{_params};
    my %merged;

    my %q = _parse_query($self->query_string);
    %merged = _merge_into({ %merged }, { %q });

    my $method = uc($self->method);
    my $ct     = $self->content_type;
    if (($method eq 'POST' || $method eq 'PUT' || $method eq 'PATCH')
        && $ct =~ m{\Aapplication/x-www-form-urlencoded}i) {
        my %p = _parse_query($self->body);
        %merged = _merge_into({ %merged }, { %p });
    }

    $self->{_params} = { %merged };
}

# Merge $parsed into a fresh copy of $merged and return the result as a
# hash whose values are always array references (so repeated keys are
# preserved in order). Returns a list, so callers reassign:
#   %merged = _merge_into({ %merged }, { %parsed });
# A fresh copy is built rather than mutating the argument, keeping the
# style under the K2/K3 copy-idiom ({ %hash }, not \%hash).
sub _merge_into {
    my ($merged, $parsed) = @_;
    my %out;
    my $k;
    for $k (keys %$merged) {
        $out{$k} = [ @{ $merged->{$k} } ];
    }
    for $k (keys %$parsed) {
        my $v = $parsed->{$k};
        my @vals = (ref($v) eq 'ARRAY') ? @$v : ($v);
        if ($out{$k}) {
            push @{ $out{$k} }, @vals;
        }
        else {
            $out{$k} = [ @vals ];
        }
    }
    return %out;
}

# --- pure-Perl query parsing and percent-decoding -------------------
# Parse an application/x-www-form-urlencoded string into a hash whose
# values are array references (so repeated keys are preserved in order).
# '+' becomes a space and %XX byte escapes are decoded.
sub _parse_query {
    my ($string) = @_;
    my %out;
    return %out unless defined $string && length $string;
    my $pair;
    for $pair (split /&/, $string) {
        next if $pair eq '';
        my ($k, $v) = split /=/, $pair, 2;
        next unless defined $k;
        $v = defined $v ? $v : '';
        $k = _url_decode($k);
        $v = _url_decode($v);
        if ($out{$k}) { push @{ $out{$k} }, $v; }
        else          { $out{$k} = [ $v ]; }
    }
    return %out;
}

# Percent-decode one form-encoded token. 5.005_03 safe: tr///, s///e with
# chr/hex, and $1 only (no //, no \x{...}, no @- / @+).
sub _url_decode {
    my ($s) = @_;
    return '' unless defined $s;
    $s =~ tr/+/ /;
    $s =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
    return $s;
}

sub _parse_cookies {
    my $self = shift;
    return if $self->{_cookies};
    my %c;
    my $raw = $self->{env}{HTTP_COOKIE};
    if (defined $raw && $raw ne '') {
        my $pair;
        for $pair (split /;\s*/, $raw) {
            my ($k, $v) = split /=/, $pair, 2;
            next unless defined $k;
            $k =~ s/\A\s+//;
            $k =~ s/\s+\z//;
            $v = defined $v ? $v : '';
            $c{$k} = _url_decode($v);
        }
    }
    $self->{_cookies} = { %c };
}

######################################################################
# PSGI::Handy::Router - tiny PSGI route dispatcher
#
# Maps (HTTP method, PATH_INFO) to a handler code reference, with named
# path parameters (:name) and an optional trailing splat (*). No named
# captures (?<name>) (5.10+); positional captures plus a parallel name
# list are used instead.
######################################################################
package PSGI::Handy::Router;

# --------------------------------------------------------------------
# new - create an empty router
# --------------------------------------------------------------------
sub new {
    my $class = shift;
    my $self = { routes => [] };
    return bless $self, $class;
}

# --------------------------------------------------------------------
# add - register a route
#   $router->add($method, $pattern, $handler);
#   $method  : 'GET', 'POST', ... (case-insensitive, stored upper-case)
#   $pattern : '/users/:id', '/files/*', '/' (must begin with '/')
#   $handler : a CODE reference
# Returns $self for chaining.
# --------------------------------------------------------------------
sub add {
    my ($self, $method, $pattern, $handler) = @_;
    defined $method            or Carp::croak "add: method is required";
    defined $pattern           or Carp::croak "add: pattern is required";
    ref($handler) eq 'CODE'    or Carp::croak "add: handler must be a code reference";
    $pattern =~ m{\A/}         or Carp::croak "add: pattern must begin with '/' (got '$pattern')";

    $method = uc($method);
    my ($regex, $names) = _compile($pattern);
    push @{ $self->{routes} }, {
        method  => $method,
        pattern => $pattern,
        regex   => $regex,
        names   => $names,
        handler => $handler,
    };
    return $self;
}

# --------------------------------------------------------------------
# match - look up a route
#   my $r = $router->match($method, $path);
# Returns:
#   - on success           : { handler => CODE, params => HASH }
#   - path matched, method not (405) : { allowed => [ method, ... ] }
#   - no match at all (404) : undef
# First registered matching route wins.
# --------------------------------------------------------------------
sub match {
    my ($self, $method, $path) = @_;
    defined $method or Carp::croak "match: method is required";
    defined $path   or Carp::croak "match: path is required";
    $method = uc($method);

    my @allowed;
    my $route;
    for $route (@{ $self->{routes} }) {
        my @caps = ($path =~ $route->{regex});
        next unless @caps;                 # this pattern did not match the path

        if ($route->{method} eq $method) {
            my %params;
            my $names = $route->{names};
            my $i;
            for ($i = 0; $i < scalar(@$names); $i++) {
                $params{ $names->[$i] } = $caps[$i];
            }
            return { handler => $route->{handler}, params => { %params } };
        }
        push @allowed, $route->{method};   # remember for a possible 405
    }

    if (@allowed) {
        my %seen;
        my @uniq = grep { !$seen{$_}++ } @allowed;
        return { allowed => \@uniq };
    }
    return undef;
}

# --------------------------------------------------------------------
# routes - return the internal route list (array reference).
# Mainly for introspection and testing.
# --------------------------------------------------------------------
sub routes {
    my $self = shift;
    return $self->{routes};
}

# --------------------------------------------------------------------
# _compile - turn a path pattern into (qr//, \@param_names)
#
# A pattern is split on '/' into segments. Each segment becomes:
#   ':name'  -> ([^/]+)   and records the parameter name 'name'
#   '*' (only as the LAST segment) -> (.*)   recorded as 'splat'
#   anything else -> quotemeta (literal, dots are NOT wildcards)
# The whole thing is anchored with \A ... \z so matching is exact.
# --------------------------------------------------------------------
sub _compile {
    my ($pattern) = @_;
    my @segs = split m{/}, $pattern, -1;   # -1 keeps trailing empty fields
    my @names;
    my @parts;
    my $last = $#segs;
    my $i;
    for ($i = 0; $i <= $last; $i++) {
        my $seg = $segs[$i];
        if ($seg eq '*' && $i == $last) {
            push @parts, '(.*)';
            push @names, 'splat';
        }
        elsif ($seg =~ /\A:([A-Za-z_]\w*)\z/) {
            push @parts, '([^/]+)';
            push @names, $1;
        }
        else {
            push @parts, quotemeta($seg);
        }
    }
    my $source = '\\A' . join('/', @parts) . '\\z';
    my $regex  = qr{$source};
    return ($regex, \@names);
}

######################################################################
# PSGI::Handy::Context - per-request context object
#
# Passed as the single argument to every route handler. Gives access to
# the request, the matched path parameters, a per-request stash, the
# injected database handle, response shortcuts, and template rendering.
######################################################################
package PSGI::Handy::Context;

sub new {
    my ($class, %args) = @_;
    my $self = {
        app    => $args{app},
        req    => $args{req},
        params => (defined $args{params} ? $args{params} : {}),
        stash  => {},
    };
    return bless $self, $class;
}

# --- accessors --------------------------------------------------------
sub req {
    my $self = shift;
    return $self->{req};
}

sub app {
    my $self = shift;
    return $self->{app};
}

# All matched path parameters (hash reference).
sub params {
    my $self = shift;
    return $self->{params};
}

# A single value: a matched path parameter wins over query/body params.
sub param {
    my ($self, $name) = @_;
    return undef unless defined $name;
    return $self->{params}{$name} if exists $self->{params}{$name};
    return $self->{req}->param($name);
}

# The injected database handle (whatever was passed to PSGI::Handy->new).
sub db {
    my $self = shift;
    return $self->{app}->db;
}

# Configuration: $c->config or $c->config($key)
sub config {
    my ($self, $key) = @_;
    return $self->{app}->config($key);
}

# --- stash ------------------------------------------------------------
#   $c->stash                 -> hashref of everything
#   $c->stash('key')          -> one value
#   $c->stash(k1 => v1, ...)  -> set, returns $c
sub stash {
    my $self = shift;
    return $self->{stash} if @_ == 0;
    return $self->{stash}{ $_[0] } if @_ == 1;
    my %kv = @_;
    my $k;
    for $k (keys %kv) {
        $self->{stash}{$k} = $kv{$k};
    }
    return $self;
}

# --- response shortcuts (return a PSGI::Handy::Response object) -------
sub html     { my $self = shift; return PSGI::Handy::Response->html(@_); }
sub text     { my $self = shift; return PSGI::Handy::Response->text(@_); }
sub json     { my $self = shift; return PSGI::Handy::Response->json(@_); }
sub redirect { my $self = shift; return PSGI::Handy::Response->redirect(@_); }
sub res      { my $self = shift; return PSGI::Handy::Response->new(@_); }

# --- template rendering ----------------------------------------------
# Uses the renderer injected into PSGI::Handy->new(renderer => ...).
# The renderer is either:
#   - a CODE reference: $renderer->($template, \%vars) -> string
#   - an object with a render() method: $r->render($template, \%vars)
# Stash values are passed to the template, overridden by $vars.
# Returns a PSGI::Handy::Response (text/html).
sub render {
    my ($self, $template, $vars) = @_;
    my $renderer = $self->{app}->renderer;
    defined $renderer
        or Carp::croak "render: no renderer configured (pass renderer => ... to PSGI::Handy->new)";

    my %merged = %{ $self->{stash} };
    if ($vars) {
        my $k;
        for $k (keys %$vars) {
            $merged{$k} = $vars->{$k};
        }
    }

    my $out;
    if (ref($renderer) eq 'CODE') {
        $out = $renderer->($template, { %merged });
    }
    elsif (ref($renderer) && UNIVERSAL::can($renderer, 'render')) {
        $out = $renderer->render($template, { %merged });
    }
    else {
        Carp::croak "render: renderer must be a code reference or an object with a render() method";
    }

    my $body = defined $out ? "$out" : '';
    return PSGI::Handy::Response->html($body);
}

######################################################################
# PSGI::Handy - the application class (facade). Wires the component
# classes above into a single PSGI-subset $app via to_app().
######################################################################
package PSGI::Handy;

# --------------------------------------------------------------------
# new(%args)
#   renderer  => CODE or object with render()   (for $c->render)
#   db        => any database handle            (for $c->db)
#   config    => hash reference                 (for $c->config)
#   not_found => CODE handler for 404           (optional)
# --------------------------------------------------------------------
sub new {
    my ($class, %args) = @_;
    my $self = {
        router    => PSGI::Handy::Router->new,
        renderer  => $args{renderer},
        db        => $args{db},
        config    => (defined $args{config} ? $args{config} : {}),
        not_found => $args{not_found},
        before    => [],
        after     => [],
    };
    return bless $self, $class;
}

# --- injected dependencies (getters / setters) ----------------------
sub renderer {
    my $self = shift;
    $self->{renderer} = shift if @_;
    return $self->{renderer};
}

sub db {
    my $self = shift;
    $self->{db} = shift if @_;
    return $self->{db};
}

sub config {
    my ($self, $key) = @_;
    return $self->{config} unless defined $key;
    return $self->{config}{$key};
}

sub router {
    my $self = shift;
    return $self->{router};
}

# --- route registration ---------------------------------------------
sub route {
    my ($self, $method, $pattern, $handler) = @_;
    $self->{router}->add($method, $pattern, $handler);
    return $self;
}

sub get   { my $self = shift; return $self->route('GET',    @_); }
sub post  { my $self = shift; return $self->route('POST',   @_); }
sub put   { my $self = shift; return $self->route('PUT',    @_); }
sub patch { my $self = shift; return $self->route('PATCH',  @_); }
sub del   { my $self = shift; return $self->route('DELETE', @_); }
sub head  { my $self = shift; return $self->route('HEAD',   @_); }

# Register a handler for every common method.
sub any {
    my ($self, $pattern, $handler) = @_;
    my $m;
    for $m (qw(GET POST PUT PATCH DELETE HEAD OPTIONS)) {
        $self->{router}->add($m, $pattern, $handler);
    }
    return $self;
}

# --- hooks ------------------------------------------------------------
# before($c): return a Response/arrayref to short-circuit, else nothing.
# after($c, $out): return a value to replace $out, else it is unchanged.
sub before {
    my ($self, $code) = @_;
    ref($code) eq 'CODE' or Carp::croak "before: a code reference is required";
    push @{ $self->{before} }, $code;
    return $self;
}

sub after {
    my ($self, $code) = @_;
    ref($code) eq 'CODE' or Carp::croak "after: a code reference is required";
    push @{ $self->{after} }, $code;
    return $self;
}

# --- build the PSGI application -------------------------------------
sub to_app {
    my $self = shift;
    return sub {
        my $env = shift;
        return $self->_dispatch($env);
    };
}

# --------------------------------------------------------------------
# _dispatch - turn one PSGI env into one PSGI response
# --------------------------------------------------------------------
sub _dispatch {
    my ($self, $env) = @_;
    my $req    = PSGI::Handy::Request->new($env);
    my $method = uc($req->method);
    my $path   = $req->path;

    my $found = $self->{router}->match($method, $path);
    if ($method eq 'HEAD' && !($found && $found->{handler})) {
        my $g = $self->{router}->match('GET', $path);    # HEAD falls back to GET
        $found = $g if $g && $g->{handler};
    }

    my $c = PSGI::Handy::Context->new(
        app    => $self,
        req    => $req,
        params => ($found && $found->{params}) ? $found->{params} : {},
    );

    my $out;
    if ($found && $found->{handler}) {
        my $short = $self->_run_before($c);
        if (defined $short) {
            $out = $short;
        }
        else {
            $out = eval { $found->{handler}->($c) };
            if ($@) {
                _log_error($env, $@);
                $out = PSGI::Handy::Response->text('Internal Server Error', 500);
            }
        }
    }
    elsif ($found && $found->{allowed}) {
        my @allow = _augment_allowed($found->{allowed});
        if ($method eq 'OPTIONS') {
            # No explicit OPTIONS route: answer the preflight ourselves.
            $out = PSGI::Handy::Response->text('', 204)
                     ->set_header('Allow', join(', ', @allow));
        }
        else {
            $out = PSGI::Handy::Response->text('Method Not Allowed', 405)
                     ->set_header('Allow', join(', ', @allow));
        }
    }
    else {
        $out = $self->_handle_not_found($c, $env);
    }

    $out = $self->_run_after($c, $out);

    my $psgi = $self->_finalize_output($out);

    # Correct HEAD semantics: keep headers (incl. Content-Length), drop body.
    if ($method eq 'HEAD') {
        return [ $psgi->[0], $psgi->[1], [] ];
    }
    return $psgi;
}

sub _handle_not_found {
    my ($self, $c, $env) = @_;
    if ($self->{not_found}) {
        my $out = eval { $self->{not_found}->($c) };
        if ($@) {
            _log_error($env, $@);
            return PSGI::Handy::Response->text('Not Found', 404);
        }
        return defined $out ? $out : PSGI::Handy::Response->text('Not Found', 404);
    }
    return PSGI::Handy::Response->text('Not Found', 404);
}

# Augment a router 'allowed' list for the Allow header. HEAD is implied
# wherever GET is served (the dispatcher serves HEAD via the GET handler),
# and OPTIONS is always answerable here. Order is preserved; the two
# implied methods are appended once if missing.
sub _augment_allowed {
    my ($allowed) = @_;
    my %seen;
    my @out;
    my $m;
    for $m (@$allowed) {
        push @out, $m unless $seen{$m}++;
    }
    if ($seen{'GET'} && !$seen{'HEAD'}) {
        push @out, 'HEAD';
        $seen{'HEAD'} = 1;
    }
    unless ($seen{'OPTIONS'}) {
        push @out, 'OPTIONS';
        $seen{'OPTIONS'} = 1;
    }
    return @out;
}

sub _run_before {
    my ($self, $c) = @_;
    my $hook;
    for $hook (@{ $self->{before} }) {
        my $r = $hook->($c);
        return $r if defined $r && ref($r);   # a ref means "use this as the response"
    }
    return undef;
}

sub _run_after {
    my ($self, $c, $out) = @_;
    my $hook;
    for $hook (@{ $self->{after} }) {
        my $r = $hook->($c, $out);
        $out = $r if defined $r;
    }
    return $out;
}

# Accept a Response object, a raw PSGI arrayref, or a plain string.
sub _finalize_output {
    my ($self, $out) = @_;
    if (ref($out) eq 'ARRAY') {
        return $out;
    }
    if (UNIVERSAL::isa($out, 'PSGI::Handy::Response')) {
        return $out->finalize;
    }
    if (!ref($out) && defined $out) {
        return PSGI::Handy::Response->html($out)->finalize;
    }
    return PSGI::Handy::Response->text('Internal Server Error', 500)->finalize;
}

sub _log_error {
    my ($env, $msg) = @_;
    my $fh = $env->{'psgi.errors'};
    return unless $fh;
    my $line = "[PSGI::Handy] handler error: $msg\n";
    # PSGI guarantees psgi.errors supports a print() method, so prefer the
    # method call (UNIVERSAL::can is used as a plain function so it is safe
    # on unblessed glob references, where it simply returns false). Plain
    # glob filehandles such as \*STDERR fall back to the block-handle form.
    if (ref($fh) && UNIVERSAL::can($fh, 'print')) {
        $fh->print($line);
    }
    else {
        print {$fh} $line;
    }
}

# --------------------------------------------------------------------
# All component classes are defined above, in this one file. Mark their
# module names as already loaded so that "use PSGI::Handy::Router" (and
# "require ...") elsewhere is a successful no-op, and give each the
# distribution $VERSION from the single source above (there is no
# per-package version literal that could drift out of step).
# --------------------------------------------------------------------
{
    no strict 'refs';
    my $loaded = defined $INC{'PSGI/Handy.pm'} ? $INC{'PSGI/Handy.pm'} : __FILE__;
    my $name;
    for $name (qw(Response Request Router Context)) {
        ${ 'PSGI::Handy::' . $name . '::VERSION' } = $VERSION;
        $INC{ 'PSGI/Handy/' . $name . '.pm' } = $loaded;
    }
}

1;

__END__

=head1 NAME

PSGI::Handy - a tiny dependency-free PSGI web framework for Perl 5.005_03 and later

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use PSGI::Handy;

    my $app = PSGI::Handy->new(
        renderer => \&my_template_renderer,   # or an object with render()
        db       => $dbh,                     # any database handle
    );

    $app->get('/', sub {
        my $c = shift;
        return $c->html('<h1>Hello</h1>');
    });

    $app->get('/users/:id', sub {
        my $c = shift;
        return $c->render('user.html', { id => $c->param('id') });
    });

    $app->post('/users', sub {
        my $c = shift;
        my $name = $c->param('name');
        # ... use $c->db ...
        return $c->redirect('/');
    });

    # PSGI::Handy builds the PSGI app; serve it with any PSGI server:
    my $psgi_app = $app->to_app;   # sub { my $env = shift; ... }

    # for example, with HTTP::Handy as the delivery layer:
    use HTTP::Handy;
    HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);

=head1 TABLE OF CONTENTS

=over 4

=item * L</DESCRIPTION>

=item * L</METHODS>

=item * L</DIAGNOSTICS>

=item * L</LIMITATIONS>

=item * L</PSGI::Handy::Router>

=item * L</PSGI::Handy::Request>

=item * L</PSGI::Handy::Response>

=item * L</PSGI::Handy::Context>

=item * L</SEE ALSO>

=back

=head1 DESCRIPTION

PSGI::Handy is the application layer of the "Handy" stack. It wires a
router (L</PSGI::Handy::Router>), a request and a response object
(L</PSGI::Handy::Request>, L</PSGI::Handy::Response>) and a per-request
context (L</PSGI::Handy::Context>) into a single PSGI-subset C<$app>
through C<to_app>. Templates and a database handle are injected at
construction time, so the framework loads nothing outside the Perl core
and stays easy to test. You serve the resulting C<$app> with any PSGI
server, such as L<HTTP::Handy>.

All four component classes are defined in this one file; there are no
separate C<PSGI/Handy/*.pm> files to install or to keep in version step.
Their module names are still loadable (C<use PSGI::Handy::Router> is a
no-op once C<PSGI::Handy> is loaded), and each is documented in its own
section below so that C<perldoc PSGI::Handy> covers the whole framework.

Every handler receives a context (L</PSGI::Handy::Context>) and may
return a Response object, a raw PSGI array reference, or a plain string
(treated as an HTML 200 response).

=head1 METHODS

These are the methods of the C<PSGI::Handy> application object:

new, renderer, db, config, router, route, get, post, put, patch, del,
head, any, before, after, to_app.

Routing details (named C<:params>, trailing C<*>, exact matching, 405
handling) are documented under L</PSGI::Handy::Router>.

=head1 DIAGNOSTICS

The framework dies (via C<Carp::croak>) with these messages. They are
collected here for the whole single-file distribution.

=over 4

=item C<before: a code reference is required>

The argument to C<before> was not a CODE reference.

=item C<after: a code reference is required>

The argument to C<after> was not a CODE reference.

=item C<new: a PSGI env hash reference is required>

C<PSGI::Handy::Request::new> was called without a PSGI environment hash
reference.

=item C<add: method is required>

C<PSGI::Handy::Router::add> was called without an HTTP method.

=item C<add: pattern is required>

C<PSGI::Handy::Router::add> was called without a path pattern.

=item C<add: handler must be a code reference>

The handler passed to C<PSGI::Handy::Router::add> was not a CODE reference.

=item C<add: pattern must begin with '/' (got '$pattern')>

The path pattern passed to C<PSGI::Handy::Router::add> did not begin with
a slash.

=item C<match: method is required>

C<PSGI::Handy::Router::match> was called without an HTTP method.

=item C<match: path is required>

C<PSGI::Handy::Router::match> was called without a path.

=item C<redirect: location is required>

C<PSGI::Handy::Response::redirect> was called without a target location.

=item C<json: body must be a pre-encoded JSON string, not a reference>

C<PSGI::Handy::Response::json> was given a reference (array or hash). The
body must be a JSON string that the caller has already encoded (for
example with C<mb::JSON>).

=item C<cookie: name is required>

C<PSGI::Handy::Response::cookie> was called without a cookie name.

=item C<render: no renderer configured (pass renderer => ... to PSGI::Handy->new)>

C<render> was called but no renderer was injected into the application.

=item C<render: renderer must be a code reference or an object with a render() method>

The configured renderer is neither a CODE reference nor an object with a
C<render> method.

=back

=head1 LIMITATIONS

The C<$app> returned by C<to_app> always produces the buffered,
three-element PSGI response C<[ $status, \@headers, \@body ]>. The PSGI
delayed-response form (the streaming "responder" callback) is not
generated; this is what "PSGI-subset" means throughout this distribution.

Concurrency and the HTTP version depend on the PSGI server you choose.
No multipart uploads or WebSocket in this version. C<HEAD> requests are
served by the matching C<GET> route with the body removed.

=head1 PSGI::Handy::Router

A tiny PSGI route dispatcher. It resolves an incoming request, expressed
as an HTTP method and a C<PATH_INFO> string, to a previously registered
handler.

=head2 Pattern syntax

=over 4

=item * Literal segments match exactly. A dot is a literal dot, not a
regular-expression wildcard (C</feed.xml> does not match C</feedaxml>).

=item * C<:name> matches a single non-empty path segment (C<[^/]+>) and
stores it in C<params> under C<name>.

=item * A C<*> used as the final segment matches the remainder of the
path, including slashes, and is stored under C<splat>.

=back

Matching is exact (anchored), so a trailing slash is significant:
C</a> and C</a/> are different routes.

=head2 Router methods

=over 4

=item new

Returns a new, empty router.

=item add($method, $pattern, $handler)

Registers a route. C<$handler> must be a code reference. C<$pattern>
must begin with C</>. Returns the router for chaining.

=item match($method, $path)

Returns a hash reference C<{ handler =E<gt> ..., params =E<gt> ... }> on
success, C<{ allowed =E<gt> [...] }> when the path is known but the
method is not (HTTP 405), or C<undef> when nothing matched (HTTP 404).
The first registered matching route wins.

=item routes

Returns the internal array reference of route records. For introspection
and testing.

=back

Path parameters rely on positional captures paired with a name list
because named captures were not available until Perl 5.10.

=head1 PSGI::Handy::Request

A tiny PSGI environment wrapper. It provides convenient read access to
the request. Query-string and C<application/x-www-form-urlencoded> body
parameters are parsed in pure Perl and merged (body values appended after
query values); multi-value fields are available through C<param_all>.
C<multipart/form-data> is not parsed in this version; use C<body> for the
raw payload.

=head2 Request methods

new, method, path, query_string, content_type, content_length, env,
header, body, param, param_all, param_names, params, cookie, cookies.

=head1 PSGI::Handy::Response

A tiny PSGI response builder. C<finalize> returns the PSGI three-element
array a PSGI-subset server such as L<HTTP::Handy> expects.
C<Content-Length> is computed from the body at finalize time unless the
caller already set it. Bodies are expected to be byte strings already in
the desired encoding; the class does no character encoding itself.

=head2 Response methods

new, html, text, json, redirect, status, set_status, body, set_body,
header, set_header, remove_header, content_type, cookie, finalize.
Mutators return the object for chaining; for example:

    my $res = PSGI::Handy::Response->new;
    $res->set_status(201)
        ->content_type('text/html; charset=utf-8')
        ->header('X-App', 'PSGI::Handy')
        ->cookie('sid', $id, path => '/', httponly => 1)
        ->set_body($html);
    return $res->finalize;   # [ 201, [...], [ $html ] ]

=head1 PSGI::Handy::Context

The per-request context handed to every route handler as its single
argument. It exposes the request (C<req>), matched path parameters
(C<param>, C<params>), a per-request C<stash>, the injected database
handle (C<db>), configuration (C<config>), response builders (C<html>,
C<text>, C<json>, C<redirect>, C<res>), and template rendering
(C<render>).

=head2 Context methods

new, req, app, params, param, db, config, stash, html, text, json,
redirect, res, render.

=head1 SEE ALSO

L<HTTP::Handy>, L<HP::Handy>, L<DB::Handy>.

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This software is distributed under the same terms as Perl itself.

=cut
