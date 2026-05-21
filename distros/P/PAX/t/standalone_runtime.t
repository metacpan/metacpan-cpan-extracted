use strict;
use warnings;
use Test::More;
use Capture::Tiny qw(capture);
use JSON::PP qw(encode_json);

use lib 'lib';
use PAX::StandaloneRuntime ();

my ($stdout, $stderr, $exit_code) = PAX::StandaloneRuntime::_capture_system_command($^X, '-e', 'print "ok\n";');
is($exit_code, 0, '_capture_system_command returns successful exit status');
is($stdout, "ok\n", '_capture_system_command captures stdout');
is($stderr, '', '_capture_system_command captures empty stderr for clean command');

my ($missing_stdout, $missing_stderr, $missing_exit) = PAX::StandaloneRuntime::_capture_system_command('pax-command-that-does-not-exist-xyz');
is($missing_stdout, '', '_capture_system_command keeps stdout empty for missing command');
ok(PAX::StandaloneRuntime::_system_command_missing($missing_stderr, $missing_exit), '_system_command_missing recognises missing host tools');

{
    local $ENV{PAX_STANDALONE_EXECUTABLE} = '/tmp/pax-demo';
    my $wrapper = PAX::StandaloneRuntime::_standalone_internal_cli_wrapper_content('shell');
    like($wrapper, qr{exec '/tmp/pax-demo' --pax-standalone-helper 'shell' "\$@"}, 'standalone helper wrapper targets the standalone executable path');
}

{
    my $shape = {
        kind => 'i64_masked_mix_accum_loop',
        args => ['n'],
    };
    my $source = <<'PERL';
# Mirror the long-running masked-mix loop shape so standalone runtime tests can
# validate script-native dispatch and fallback behavior.
sub dot_i64 {
    my ($n) = @_;
    my $acc = 0;
    for (my $i = 0; $i < $n; $i++) {
        $acc += (($i * 13) ^ ($i >> 3)) & 0xFFFF;
    }
    return $acc;
}

print dot_i64(8), "\n";
PERL
    my $rewritten = PAX::StandaloneRuntime::_apply_compiled_script_subs($source, [{
        op => 'native_shape_sub',
        name => 'dot_i64',
        full_name => 'main::dot_i64',
        prototype => undef,
        native_shape => $shape,
    }]);
    like($rewritten, qr/_run_native_shape_sub\('main::dot_i64'/, 'compiled script source rewrites native-capable sub bodies through standalone runtime dispatcher');
    is(index($rewritten, '(($i * 13) ^ ($i >> 3)) & 0xFFFF'), -1, 'compiled script source removes original Perl loop body for rewritten native sub');
}

{
    no warnings 'redefine';
    my @calls;
    local *PAX::StandaloneRuntime::_invoke_native_shape_runtime = sub {
        my ($full, $shape, $args) = @_;
        push @calls, [$full, $shape->{kind}, [@$args]];
        return {
            status => 'ok',
            value => 360,
        };
    };
    my $value = PAX::StandaloneRuntime::_run_native_shape_sub('main::dot_i64', {
        kind => 'i64_masked_mix_accum_loop',
        args => ['n'],
    }, 8);
    is($value, 360, 'native shape helper returns the native runtime value when a bundled artifact is available');
    is_deeply(\@calls, [
        ['main::dot_i64', 'i64_masked_mix_accum_loop', [8]],
    ], 'native shape helper dispatches unary loop shapes through the bundled native artifact path');
}

{
    my $bin_dir = 't/tmp-standalone-bin';
    mkdir $bin_dir if !-d $bin_dir;
    open my $fh, '>', "$bin_dir/pax-demo" or die "cannot write fake standalone executable: $!";
    print {$fh} "#!/bin/sh\nexit 0\n";
    close $fh;
    chmod 0755, "$bin_dir/pax-demo";
    require Cwd;
    my $expected = Cwd::abs_path("$bin_dir/pax-demo");
    local $ENV{PATH} = join(':', $bin_dir, ($ENV{PATH} // ''));
    local $ENV{PAX_STANDALONE_EXECUTABLE} = 'pax-demo';
    my $resolved = PAX::StandaloneRuntime::_standalone_executable_path();
    is($resolved, $expected, 'standalone executable path resolves argv[0] through PATH');
    unlink "$bin_dir/pax-demo";
    rmdir $bin_dir;
}

{
    no warnings 'redefine';
    local $ENV{PAX_STANDALONE_EXECUTABLE} = '/tmp/pax-demo';
    my $fake_state = {
        manifest => {
            code_units => [],
            native_dispatch => [],
            app => {},
        },
        root => 't/tmp-standalone-runtime-root',
        app_namespace => '',
        legacy_namespace => '',
        compiled_packages => {},
        app_env_prefix => undef,
        native_runner => bless({}, 'PAX::NativeRunner'),
        wrapped => {},
        namespace_aliases => {},
        by_region => {},
        compiled_units => {},
        require_hook_installed => 0,
        loading_require => {},
        residual_loaded => {},
        residual_bootstrap_loaded => {},
    };
    local *PAX::StandaloneRuntime::_state = sub { return $fake_state };
    local *PAX::StandaloneRuntime::_install_namespace_compat = sub { return 1 };
    local *PAX::StandaloneRuntime::_install_require_hook = sub { return 1 };
    local *PAX::StandaloneRuntime::_install_pending_wrappers = sub { return 1 };
    local *PAX::StandaloneRuntime::_run_entrypoint = sub {
        return $0;
    };
    my $result = PAX::StandaloneRuntime->run(
        entrypoint => 'entrypoint.pl',
        argv => [],
    );
    is($result, '/tmp/pax-demo', 'standalone runtime runs entrypoint with the standalone executable path as $0');
}

{
    no warnings 'redefine';
    my @asset_requests;
    local *PAX::StandaloneRuntime::_standalone_executable_path = sub { return '/tmp/pax-demo' };
    local *PAX::StandaloneRuntime::_standalone_internal_cli_asset_content = sub {
        my ($name) = @_;
        push @asset_requests, $name;
        return ("print join(q{|}, q{direct}, \$0, \@ARGV), qq{\\n}; 0;\n", "/tmp/$name")
            if $name eq 'ps1';
        die "unexpected helper asset lookup for $name";
    };
    my ($stdout, $stderr, $result) = capture {
        PAX::StandaloneRuntime::_run_standalone_managed_helper('ps1', '--jobs', '1');
    };
    is($result, 0, 'direct standalone helper execution returns success');
    is($stderr, '', 'direct standalone helper execution keeps stderr empty');
    like($stdout, qr{\Adirect\|/tmp/ps1\|--jobs\|1\n\z}, 'direct standalone helper execution preserves helper path and argv');
    is_deeply(\@asset_requests, ['ps1'], 'direct standalone helper execution loads only the requested helper asset');
}

{
    no warnings 'redefine';
    my @asset_requests;
    local $ENV{PAX_STANDALONE_EXECUTABLE} = '/tmp/pax-demo';
    local *PAX::StandaloneRuntime::_standalone_executable_path = sub { return '/tmp/pax-demo' };
    local *PAX::StandaloneRuntime::_standalone_internal_cli_asset_content = sub {
        my ($name) = @_;
        push @asset_requests, $name;
        return ('my $command = basename($0);' . "\n"
              . 'my $core = q{/tmp/_dashboard-core};' . "\n"
              . 'exec { $^X } $^X, $core, $command, @ARGV;' . "\n", '/tmp/shell')
            if $name eq 'shell';
        return ("print join(q{|}, q{core}, \@ARGV), qq{\\n}; 0;\n", '/tmp/_dashboard-core')
            if $name eq '_dashboard-core';
        die "unexpected helper asset lookup for $name";
    };
    my ($stdout, $stderr, $result) = capture {
        PAX::StandaloneRuntime::_run_standalone_managed_helper('shell', 'bash');
    };
    is($result, 0, 'delegating standalone helper execution returns success');
    is($stderr, '', 'delegating standalone helper execution keeps stderr empty');
    like($stdout, qr{\Acore\|shell\|bash\n\z}, 'delegating standalone helper execution routes through dashboard core with helper name');
    is_deeply(\@asset_requests, ['shell', '_dashboard-core'], 'delegating standalone helper execution loads helper asset and dashboard core');
}

{
    no warnings 'redefine';
    my $entrypoint = 't/tmp-standalone-runtime-cli-router.json';
    open my $fh, '>', $entrypoint or die "cannot write cli router fixture: $!";
    print {$fh} encode_json({
        version_module => 'Example::App',
        suggest_class => 'Example::Suggest',
    });
    close $fh;

    my @helper_calls;
    my $switchboard_calls = 0;
    local *PAX::StandaloneRuntime::_run_standalone_managed_helper = sub {
        my ($name, @argv) = @_;
        push @helper_calls, [$name, @argv];
        return 'direct-helper';
    };
    local *PAX::StandaloneRuntime::_virtual_entrypoint_path = sub {
        my ($path) = @_;
        return $path;
    };
    local *PAX::StandaloneRuntime::_code_for = sub {
        my ($name) = @_;
        return sub { return 1 } if $name eq 'main::_load_runtime_env';
        return sub { return 1 } if $name eq 'main::_prime_command_result_env';
        return sub {
            my ($cmd) = @_;
            return '/tmp/runtime-helpers/ps1' if $cmd eq 'ps1';
            return '/tmp/runtime-helpers/skills' if $cmd eq 'skills';
            return '';
        } if $name eq 'main::_builtin_helper_path';
        return sub { return '' } if $name eq 'main::_custom_command_path';
        return sub {
            my ($cmd) = @_;
            return ('sample-skill', 'run-test') if $cmd eq 'sample-skill.run-test';
            return;
        } if $name eq 'main::_skill_dotted_command_parts';
        return sub {
            $switchboard_calls++;
            die 'switchboard path should not run';
        } if $name eq 'main::_exec_switchboard_command';
        return;
    };

    {
        local @ARGV = ('ps1', '--jobs', '1');
        my $rv = PAX::StandaloneRuntime::_run_cli_router_unit($entrypoint);
        is($rv, 'direct-helper', 'cli router routes built-in helper commands through the standalone helper fast path');
    }

    {
        local @ARGV = ('sample-skill.run-test', '--verbose');
        my $rv = PAX::StandaloneRuntime::_run_cli_router_unit($entrypoint);
        is($rv, 'direct-helper', 'cli router routes dotted skill commands through the standalone helper fast path');
    }

    is_deeply(
        \@helper_calls,
        [
            ['ps1', '--jobs', '1'],
            ['skills', '_exec', 'sample-skill', 'run-test', '--verbose'],
        ],
        'cli router fast path preserves helper name and argv for built-in and skill helper dispatch',
    );
    is($switchboard_calls, 0, 'cli router helper fast path skips switchboard execution');

    unlink $entrypoint or die "cannot remove cli router fixture $entrypoint: $!";
}

done_testing;

=pod

=head1 NAME

t/standalone_runtime.t - regression coverage for standalone runtime dispatch, helper routing, and bootstrap behavior

=head1 DESCRIPTION

This test exercises standalone runtime dispatch, helper routing, and bootstrap behavior. It exists so PAX changes can be checked against a
repeatable behavioral contract instead of informal manual runs.

=head1 TEST PLAN

The assertions in this file cover the specific success, failure, and edge-case
paths needed for standalone runtime dispatch, helper routing, and bootstrap behavior. Extend this file when behavior changes in that area.

=head1 HOW TO RUN

  prove -lv t/standalone_runtime.t

=head1 WHY IT EXISTS

PAX uses this test to keep standalone runtime dispatch, helper routing, and bootstrap behavior from regressing while the compiler,
standalone runtime, and packaging logic continue to evolve.

=cut
