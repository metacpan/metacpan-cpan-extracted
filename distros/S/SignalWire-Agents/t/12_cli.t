#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON qw(encode_json decode_json);
use MIME::Base64 qw(encode_base64);
use File::Spec;

# ============================================================
# 1. swaig-test script exists and is executable
# ============================================================
subtest 'swaig-test script exists' => sub {
    my $script = File::Spec->catfile('bin', 'swaig-test');
    ok(-f $script, 'bin/swaig-test exists');
    ok(-x $script, 'bin/swaig-test is executable');
};

# ============================================================
# 2. swaig-test --help exits cleanly
# ============================================================
subtest 'swaig-test --help' => sub {
    my $output = `PERL5LIB="lib:\$PERL5LIB" $^X bin/swaig-test --help 2>&1`;
    like($output, qr/Usage/, 'help output contains Usage');
    like($output, qr/--url/, 'help mentions --url');
    like($output, qr/--dump-swml/, 'help mentions --dump-swml');
    like($output, qr/--list-tools/, 'help mentions --list-tools');
    like($output, qr/--exec/, 'help mentions --exec');
    like($output, qr/--param/, 'help mentions --param');
    like($output, qr/--raw/, 'help mentions --raw');
    like($output, qr/--verbose/, 'help mentions --verbose');
};

# ============================================================
# 3. swaig-test errors without --url
# ============================================================
subtest 'swaig-test requires --url' => sub {
    my $output = `PERL5LIB="lib:\$PERL5LIB" $^X bin/swaig-test --dump-swml 2>&1`;
    like($output, qr/--url is required/i, 'errors when no --url provided');
};

# ============================================================
# 4. swaig-test requires an action
# ============================================================
subtest 'swaig-test requires action' => sub {
    my $output = `PERL5LIB="lib:\$PERL5LIB" $^X bin/swaig-test --url http://user:pass\@localhost:9999/ 2>&1`;
    like($output, qr/--dump-swml|--list-tools|--exec/, 'errors when no action provided');
};

# ============================================================
# 5. Integration test: start a PSGI agent, test dump-swml via HTTP
# ============================================================
subtest 'swaig-test integration with live agent' => sub {
    # Use the agent PSGI app directly to simulate HTTP without needing a real server
    require SignalWire::Agents::Agent::AgentBase;
    my $agent = SignalWire::Agents::Agent::AgentBase->new(
        name               => 'cli_test_agent',
        route              => '/',
        basic_auth_user    => 'testuser',
        basic_auth_password => 'testpass',
    );

    $agent->prompt_add_section('Role', 'You are a test agent.');
    $agent->define_tool(
        name        => 'greet',
        description => 'Greet the user',
        parameters  => {
            type       => 'object',
            properties => {
                name => { type => 'string', description => 'Name to greet' },
            },
            required => ['name'],
        },
        handler => sub {
            my ($args) = @_;
            return { response => "Hello, $args->{name}!" };
        },
    );

    my $app = $agent->psgi_app;
    my $auth = encode_base64('testuser:testpass', '');

    # Simulate GET for SWML
    my $swml_res = $app->({
        REQUEST_METHOD     => 'GET',
        PATH_INFO          => '/',
        SCRIPT_NAME        => '',
        SERVER_NAME        => 'localhost',
        SERVER_PORT        => 3000,
        HTTP_AUTHORIZATION => "Basic $auth",
        'psgi.input'       => do { open my $fh, '<', \(''); $fh },
    });

    is($swml_res->[0], 200, 'SWML request returns 200');
    my $swml_data = decode_json($swml_res->[2][0]);
    ok(exists $swml_data->{sections}{main}, 'SWML has main section');

    # Find SWAIG functions
    my @ai_verbs = grep { ref $_ eq 'HASH' && exists $_->{ai} }
                   @{ $swml_data->{sections}{main} };
    ok(@ai_verbs, 'AI verb found');
    my $funcs = $ai_verbs[0]{ai}{SWAIG}{functions} // [];
    ok(scalar @$funcs >= 1, 'at least one SWAIG function found');
    is($funcs->[0]{function}, 'greet', 'greet function found');

    # Simulate POST to /swaig
    my $swaig_payload = encode_json({
        function => 'greet',
        argument => {
            parsed => [{ name => 'World' }],
        },
    });

    open my $input_fh, '<', \$swaig_payload;
    my $swaig_res = $app->({
        REQUEST_METHOD     => 'POST',
        PATH_INFO          => '/swaig',
        SCRIPT_NAME        => '',
        SERVER_NAME        => 'localhost',
        SERVER_PORT        => 3000,
        HTTP_AUTHORIZATION => "Basic $auth",
        CONTENT_TYPE       => 'application/json',
        CONTENT_LENGTH     => length($swaig_payload),
        'psgi.input'       => $input_fh,
    });

    is($swaig_res->[0], 200, 'SWAIG exec returns 200');
    my $swaig_body = decode_json($swaig_res->[2][0]);
    like($swaig_body->{response}, qr/Hello.*World/, 'SWAIG exec returns greeting');
};

# ============================================================
# 6. Script compiles cleanly
# ============================================================
subtest 'swaig-test compiles' => sub {
    my $output = `PERL5LIB="lib:\$PERL5LIB" $^X -c bin/swaig-test 2>&1`;
    like($output, qr/syntax OK/, 'bin/swaig-test compiles without errors');
};

done_testing;
