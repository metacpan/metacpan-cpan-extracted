#!/usr/bin/env perl
# Tests proving SWML::Service can host SWAIG functions and serve a non-agent
# SWML doc (e.g. ai_sidecar) without subclassing AgentBase. This is the
# contract that lets sidecar / non-agent verbs reuse the SWAIG dispatch
# surface that previously lived only on AgentBase.

use strict;
use warnings;
use Test::More;
use JSON ();
use MIME::Base64 qw(encode_base64);

use SignalWire::SWML::Service;

sub make_svc {
    return SignalWire::SWML::Service->new(
        name                => 'svc',
        basic_auth_user     => 'u',
        basic_auth_password => 'p',
    );
}

sub auth_header { 'Basic ' . encode_base64('u:p', '') }

sub psgi_request {
    my ($svc, $method, $path, $body, %extra) = @_;
    my $env = {
        REQUEST_METHOD => $method,
        PATH_INFO      => $path,
        CONTENT_TYPE   => 'application/json',
        HTTP_AUTHORIZATION => auth_header(),
        %extra,
    };
    if (defined $body) {
        open my $input, '<', \$body or die $!;
        $env->{'psgi.input'}    = $input;
        $env->{CONTENT_LENGTH}  = length $body;
    } else {
        open my $input, '<', \'';
        $env->{'psgi.input'}    = $input;
    }
    return $svc->to_psgi_app->($env);
}

# -----------------------------------------------------------------------
# Service gains SWAIG-hosting capability
# -----------------------------------------------------------------------

subtest 'service has SWAIG methods' => sub {
    my $svc = make_svc();
    ok($svc->can('define_tool'), 'define_tool present');
    ok($svc->can('register_swaig_function'), 'register_swaig_function present');
    ok($svc->can('define_tools'), 'define_tools present');
    ok($svc->can('on_function_call'), 'on_function_call present');
};

subtest 'define_tool registers function and dispatches via on_function_call' => sub {
    my $svc = make_svc();
    my %captured;
    $svc->define_tool(
        name        => 'lookup',
        description => 'Look it up',
        parameters  => {},
        handler     => sub {
            my ($args) = @_;
            %captured = %$args;
            return { response => 'ok' };
        },
    );
    my $result = $svc->on_function_call('lookup', { x => 'y' }, {});
    is_deeply(\%captured, { x => 'y' }, 'handler received args');
    is($result->{response}, 'ok', 'result has response key');
};

subtest 'on_function_call returns undef for unknown' => sub {
    my $svc = make_svc();
    is($svc->on_function_call('no_such_fn', {}, {}), undef, 'unknown function => undef');
};

subtest 'list_tool_names returns registered order' => sub {
    my $svc = make_svc();
    $svc->define_tool(name => 'first', description => 'f', handler => sub { {} });
    $svc->define_tool(name => 'second', description => 's', handler => sub { {} });
    is_deeply([$svc->list_tool_names], ['first', 'second'], 'order preserved');
};

# -----------------------------------------------------------------------
# /swaig endpoint
# -----------------------------------------------------------------------

subtest 'GET /swaig returns SWML' => sub {
    my $svc = make_svc();
    $svc->hangup;
    my $res = psgi_request($svc, 'GET', '/swaig');
    is($res->[0], 200, 'status 200');
    my $body = JSON::decode_json($res->[2][0]);
    ok($body->{sections}, 'has sections');
};

subtest 'POST /swaig dispatches registered handler' => sub {
    my $svc = make_svc();
    $svc->define_tool(
        name        => 'lookup_competitor',
        description => 'Look up competitor pricing.',
        parameters  => { competitor => { type => 'string' } },
        handler     => sub {
            my ($args) = @_;
            return { response => "$args->{competitor} is \$99/seat; we're \$79." };
        },
    );
    my $payload = JSON::encode_json({
        function => 'lookup_competitor',
        argument => { parsed => [{ competitor => 'ACME' }] },
        call_id  => 'c-1',
    });
    my $res = psgi_request($svc, 'POST', '/swaig', $payload);
    is($res->[0], 200, 'status 200');
    like($res->[2][0], qr/ACME/, 'response mentions ACME');
    like($res->[2][0], qr/\$79/, 'response mentions $79');
};

subtest 'POST /swaig missing function returns 400' => sub {
    my $svc = make_svc();
    my $res = psgi_request($svc, 'POST', '/swaig', '{}');
    is($res->[0], 400, 'status 400');
};

subtest 'POST /swaig invalid function name returns 400' => sub {
    my $svc = make_svc();
    my $res = psgi_request($svc, 'POST', '/swaig',
        JSON::encode_json({ function => '../etc/passwd' }));
    is($res->[0], 400, 'status 400');
};

subtest 'POST /swaig unknown function returns 404' => sub {
    my $svc = make_svc();
    my $res = psgi_request($svc, 'POST', '/swaig',
        JSON::encode_json({ function => 'nope', argument => { parsed => [{}] } }));
    is($res->[0], 404, 'status 404');
};

subtest 'unauthorized returns 401' => sub {
    my $svc = make_svc();
    my $res = $svc->to_psgi_app->({
        REQUEST_METHOD => 'POST',
        PATH_INFO      => '/swaig',
        # No HTTP_AUTHORIZATION
    });
    is($res->[0], 401, 'status 401');
};

# -----------------------------------------------------------------------
# Sidecar pattern: non-agent SWML + tool registration + (sketch) event sink
# -----------------------------------------------------------------------

subtest 'sidecar pattern emits verb and registers tool' => sub {
    my $svc = make_svc();

    # 1. Build the SWML — answer + ai_sidecar verb config.
    $svc->answer('main', {});
    $svc->document->add_verb('main', 'ai_sidecar', {
        prompt    => 'real-time copilot',
        lang      => 'en-US',
        direction => ['remote-caller', 'local-caller'],
    });
    my $rendered = $svc->document->to_hash;
    my @verbs = map { (keys %$_)[0] } @{ $rendered->{sections}{main} };
    ok(scalar(grep { $_ eq 'answer' } @verbs), 'has answer verb');
    ok(scalar(grep { $_ eq 'ai_sidecar' } @verbs), 'has ai_sidecar verb');

    # 2. Register a SWAIG tool the sidecar's LLM can call.
    $svc->define_tool(
        name        => 'lookup_competitor',
        description => 'Look up competitor pricing.',
        parameters  => { competitor => { type => 'string' } },
        handler     => sub {
            my ($args) = @_;
            return { response => "Pricing for $args->{competitor}: \$99" };
        },
    );

    # 3. Dispatch end-to-end through the public on_function_call surface.
    my $result = $svc->on_function_call(
        'lookup_competitor',
        { competitor => 'ACME' },
        {},
    );
    like($result->{response}, qr/ACME/, 'dispatched and got ACME');
};

# -----------------------------------------------------------------------
# Python parity: extract_sip_username($body) — pulls the SIP username
# out of a request body's call.to field.
# -----------------------------------------------------------------------

subtest 'extract_sip_username: sip URI' => sub {
    my $body = { call => { to => 'sip:alice@example.com' } };
    is(SignalWire::SWML::Service->extract_sip_username($body),
       'alice', 'class-method form');
    # Free-function form (single hashref arg).
    is(SignalWire::SWML::Service::extract_sip_username($body),
       'alice', 'free-function form');
};

subtest 'extract_sip_username: tel URI' => sub {
    my $body = { call => { to => 'tel:+15551234567' } };
    is(SignalWire::SWML::Service->extract_sip_username($body),
       '+15551234567', 'TEL URI extracts E.164 number');
};

subtest 'extract_sip_username: plain destination' => sub {
    my $body = { call => { to => 'some-destination' } };
    is(SignalWire::SWML::Service->extract_sip_username($body),
       'some-destination', 'plain to field returned verbatim');
};

subtest 'extract_sip_username: SIP URI with port' => sub {
    my $body = { call => { to => 'sip:bob@example.com:5060' } };
    is(SignalWire::SWML::Service->extract_sip_username($body),
       'bob', 'username extracted before host:port');
};

subtest 'extract_sip_username: no call key returns undef' => sub {
    is(SignalWire::SWML::Service->extract_sip_username({ other => 'data' }),
       undef, 'no call key -> undef');
};

subtest 'extract_sip_username: missing to returns undef' => sub {
    is(SignalWire::SWML::Service->extract_sip_username({ call => { from => 'sip:x@y' } }),
       undef, 'missing to -> undef');
};

subtest 'extract_sip_username: empty / non-hash body returns undef' => sub {
    is(SignalWire::SWML::Service->extract_sip_username({}),     undef, 'empty hashref -> undef');
    is(SignalWire::SWML::Service->extract_sip_username(undef),  undef, 'undef -> undef');
    is(SignalWire::SWML::Service->extract_sip_username('str'),  undef, 'scalar -> undef');
    is(SignalWire::SWML::Service->extract_sip_username([1,2]),  undef, 'arrayref -> undef');
};

subtest 'extract_sip_username: non-string to returns undef' => sub {
    is(SignalWire::SWML::Service->extract_sip_username({ call => { to => 12345 } }),
       12345, 'numeric to is returned as-is per Python (no AttributeError-ish)');
    # Python strings-only, but Perl is dynamically typed; the hashref / arrayref
    # cases are the real "non-string" guard:
    is(SignalWire::SWML::Service->extract_sip_username({ call => { to => [] } }),
       undef, 'arrayref to -> undef');
    is(SignalWire::SWML::Service->extract_sip_username({ call => { to => {} } }),
       undef, 'hashref to -> undef');
};

# -----------------------------------------------------------------------
# Python parity: schema_utils / verb_registry / security accessors.
# -----------------------------------------------------------------------

subtest 'schema_utils accessor returns the schema instance' => sub {
    my $svc = make_svc();
    my $su  = $svc->schema_utils;
    isa_ok($su, 'SignalWire::SWML::Schema', 'schema_utils returns Schema instance');
    ok($su->verb_count > 0, 'schema has verbs loaded');
    # Python parity: idempotent — same instance on repeated access.
    is($svc->schema_utils, $su, 'schema_utils is memoized');
};

subtest 'verb_registry accessor returns a registry-shaped object' => sub {
    my $svc = make_svc();
    my $reg = $svc->verb_registry;
    is(ref $reg, 'HASH', 'verb_registry is a hashref');
    ok(exists $reg->{handlers}, 'has "handlers" slot (Python parity: VerbHandlerRegistry._handlers)');
    is(ref $reg->{handlers}, 'HASH', 'handlers is a hashref');
    # Mutability: callers can register a handler.
    $reg->{handlers}{custom_verb} = sub { 'ok' };
    is($svc->verb_registry->{handlers}{custom_verb}->(), 'ok', 'memoized + mutable');
};

subtest 'security accessor returns SessionManager instance' => sub {
    my $svc = make_svc();
    my $sec = $svc->security;
    isa_ok($sec, 'SignalWire::Security::SessionManager', 'security returns SessionManager');
    is($svc->security, $sec, 'security is memoized');
    ok($sec->generate_token('foo', 'bar'), 'session manager is functional');
};

# -----------------------------------------------------------------------
# Python parity: get_basic_auth_credentials($include_source).
# -----------------------------------------------------------------------

subtest 'get_basic_auth_credentials: 2-tuple by default' => sub {
    my $svc = SignalWire::SWML::Service->new(
        name                => 'creds',
        basic_auth_user     => 'alice',
        basic_auth_password => 'secret',
    );
    my @c = $svc->get_basic_auth_credentials;
    is_deeply(\@c, ['alice', 'secret'], '(user, pass) by default');
};

subtest 'get_basic_auth_credentials(1): 3-tuple with source' => sub {
    local $ENV{SWML_BASIC_AUTH_USER};
    local $ENV{SWML_BASIC_AUTH_PASSWORD};
    delete $ENV{SWML_BASIC_AUTH_USER};
    delete $ENV{SWML_BASIC_AUTH_PASSWORD};
    my $svc = SignalWire::SWML::Service->new(
        name                => 'creds_src',
        basic_auth_user     => 'alice',
        basic_auth_password => 'secret',
    );
    my @c = $svc->get_basic_auth_credentials(1);
    is(scalar @c, 3, 'three-element list');
    is($c[2], 'provided', 'source: explicit pass-through');
};

done_testing;
