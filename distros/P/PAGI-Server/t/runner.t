use strict;
use warnings;
use Test2::V0;
use FindBin;
use File::Temp qw(tempdir tempfile);
use File::Spec;
use Cwd qw(abs_path);

our $test_bin;
BEGIN { $test_bin = $FindBin::Bin; }
use lib "$test_bin/../lib";
use lib "$test_bin/lib";
use PAGI::Server::Runner;
use PAGITest::FakeServer;

# Helper: write a minimal PAGI app to a tempfile and return its path.
# Used anywhere a real file path is needed but the content does not matter.
sub _write_hello_app {
    my ($fh, $path) = tempfile(SUFFIX => '.pl', UNLINK => 1);
    print $fh <<'APP';
use strict;
use warnings;
use Future::AsyncAwait;
my $app = async sub {
    my ($scope, $receive, $send) = @_;
    die "Unsupported scope type: $scope->{type}" if $scope->{type} ne 'http';
    await $send->({ type => 'http.response.start', status => 200,
                    headers => [ [ 'content-type', 'text/plain' ] ] });
    await $send->({ type => 'http.response.body', body => 'Hello from PAGI', more => 0 });
};
$app;
APP
    close $fh;
    return $path;
}

# Test 1: Basic construction
subtest 'constructor with defaults' => sub {
    my $runner = PAGI::Server::Runner->new;

    ok(!defined $runner->{host}, 'host undef (defaults applied in load_server)');
    ok(!defined $runner->{port}, 'port undef (defaults applied in load_server)');
    is($runner->{quiet}, 0, 'default quiet');
    ok(!defined $runner->{app}, 'no app initially');
};

# Test 2: Constructor with options
subtest 'constructor with options' => sub {
    my $runner = PAGI::Server::Runner->new(
        host    => '0.0.0.0',
        port    => 8080,
        quiet   => 1,
    );

    is($runner->{host}, '0.0.0.0', 'custom host');
    is($runner->{port}, 8080, 'custom port');
    is($runner->{quiet}, 1, 'custom quiet');
};

# Test 3: Parse CLI options (runner options)
subtest 'parse runner CLI options' => sub {
    my $runner = PAGI::Server::Runner->new;
    $runner->parse_options(
        '-p', '8080',
        '-o', '0.0.0.0',
        '-q',
        'PAGI::App::Directory',
        'root=/tmp',
    );

    is($runner->{port}, 8080, 'port parsed');
    is($runner->{host}, '0.0.0.0', 'host parsed');
    is($runner->{quiet}, 1, 'quiet parsed');
    # App spec and args are now in argv
    is(scalar @{$runner->{argv}}, 2, 'two args in argv');
    is($runner->{argv}[0], 'PAGI::App::Directory', 'app spec in argv');
    is($runner->{argv}[1], 'root=/tmp', 'app arg in argv');
};

# Test 4: Parse long CLI options
subtest 'parse long CLI options' => sub {
    my $runner = PAGI::Server::Runner->new;
    $runner->parse_options(
        '--port', '9000',
        '--host', '192.168.1.1',
        '--quiet',
        '--loop', 'EV',
        'app.pl',
    );

    is($runner->{port}, 9000, 'port parsed');
    is($runner->{host}, '192.168.1.1', 'host parsed');
    is($runner->{quiet}, 1, 'quiet parsed');
    is($runner->{loop}, 'EV', 'loop parsed');
    is($runner->{argv}[0], 'app.pl', 'app file in argv');
};

# Test 5: Legacy --app flag
subtest 'legacy --app flag' => sub {
    my $runner = PAGI::Server::Runner->new;
    $runner->parse_options('--app', 'examples/01-hello-http/app.pl', '-p', '3000');

    is($runner->{app_spec}, 'examples/01-hello-http/app.pl', '--app sets app_spec');
    is($runner->{port}, 3000, 'port also parsed');
};

# Test 6: Module name detection
subtest 'module name detection' => sub {
    my $runner = PAGI::Server::Runner->new;

    ok($runner->_is_module_name('PAGI::App::Directory'), 'detects module name');
    ok($runner->_is_module_name('Foo::Bar::Baz'), 'detects any module name');
    ok(!$runner->_is_module_name('app.pl'), 'file is not module');
    ok(!$runner->_is_module_name('./path/to/app.pl'), 'path is not module');
};

# Test 7: File path detection
subtest 'file path detection' => sub {
    my $runner = PAGI::Server::Runner->new;

    ok($runner->_is_file_path('./app.pl'), 'detects relative path');
    ok($runner->_is_file_path('/path/to/app.pl'), 'detects absolute path');
    ok($runner->_is_file_path('app.pl'), 'detects .pl extension');
    ok($runner->_is_file_path('myapp.psgi'), 'detects .psgi extension');
    ok(!$runner->_is_file_path('PAGI::App::Directory'), 'module is not file');
};

# Test 8: Parse app args (key=value)
subtest 'parse app args' => sub {
    my $runner = PAGI::Server::Runner->new;
    my %args = $runner->_parse_app_args('root=/tmp', 'show_hidden=1', 'index=index.html');

    is($args{root}, '/tmp', 'root parsed');
    is($args{show_hidden}, '1', 'show_hidden parsed');
    is($args{index}, 'index.html', 'index parsed');
};

# Test 9: Load app from file
subtest 'load app from file' => sub {
    my $runner = PAGI::Server::Runner->new;
    $runner->{app_spec} = _write_hello_app();

    my $app = $runner->load_app;

    ok(ref $app eq 'CODE', 'loaded app is coderef');
    is($runner->{app}, $app, 'app stored in runner');
};

subtest 'load app from file sets FindBin::Bin to app directory' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $app_file = File::Spec->catfile($tmpdir, 'findbin_app.pl');

    open my $fh, '>', $app_file or die "Cannot write $app_file: $!";
    print $fh <<'APP';
package App::FindBinTest;
use FindBin;
our $BIN = $FindBin::Bin;
sub app { }
return \&app;
APP
    close $fh;

    my $runner = PAGI::Server::Runner->new;
    $runner->{app_spec} = $app_file;
    my $app = $runner->load_app;

    ok(ref $app eq 'CODE', 'loaded app is coderef');
    no warnings 'once';
    is(abs_path($App::FindBinTest::BIN), abs_path($tmpdir), 'FindBin::Bin matches app directory');
};

# Test 10: Load app from module (requires PAGI-Tools for PAGI::App::Directory)
subtest 'load app from module' => sub {
    SKIP: {
        skip 'PAGI::App::Directory not available (install PAGI-Tools >= 0.002000)', 4
            unless eval { require PAGI::Tools; PAGI::Tools->VERSION(0.002000); require PAGI::App::Directory; 1 };

        my $runner = PAGI::Server::Runner->new;
        $runner->{argv} = ['PAGI::App::Directory', 'root=.'];

        my $app = $runner->load_app;

        ok(ref $app eq 'CODE', 'loaded app is coderef');
        is($runner->{app}, $app, 'app stored in runner');
        is($runner->{app_spec}, 'PAGI::App::Directory', 'app_spec stored');
        is($runner->{app_args}{root}, '.', 'app_args stored');
    }
};

# Test 10b: _load_module success path with a self-contained conforming module.
# Exercises the loader seam (require -> new/to_app check -> instantiate -> coderef)
# without depending on any PAGI-Tools app, so it runs on a bare PAGI-Server install.
subtest '_load_module loads a conforming module' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $pm = File::Spec->catfile($tmpdir, 'MyConformingApp.pm');
    open my $fh, '>', $pm or die "Cannot write $pm: $!";
    print $fh <<'MOD';
package MyConformingApp;
use Future::AsyncAwait;
sub new { my ($class, %args) = @_; bless { %args }, $class }
sub to_app { my $self = shift; return async sub { } }
1;
MOD
    close $fh;

    local @INC = ($tmpdir, @INC);
    my $runner = PAGI::Server::Runner->new;
    $runner->{argv} = ['MyConformingApp', 'root=/tmp'];

    my $app = $runner->load_app;

    ok(ref $app eq 'CODE', '_load_module returns a coderef for a conforming module');
    is($runner->{app_spec}, 'MyConformingApp', 'module app_spec stored');
    is($runner->{app_args}{root}, '/tmp', 'module app_args parsed');
};

# Test 11: Default app (requires PAGI-Tools for PAGI::App::Directory)
subtest 'default app loads Directory' => sub {
    SKIP: {
        skip 'PAGI::App::Directory not available (install PAGI-Tools >= 0.002000)', 3
            unless eval { require PAGI::Tools; PAGI::Tools->VERSION(0.002000); require PAGI::App::Directory; 1 };

        my $runner = PAGI::Server::Runner->new;
        my $app = $runner->load_app;

        ok(ref $app eq 'CODE', 'default app is coderef');
        is($runner->{app_spec}, 'PAGI::App::Directory', 'default is Directory');
        is($runner->{app_args}{root}, '.', 'default root is current dir');
    }
};

# Test 12: Error on missing file
subtest 'error on missing file' => sub {
    my $runner = PAGI::Server::Runner->new;
    $runner->{app_spec} = 'nonexistent_file_12345.pl';

    like(
        dies { $runner->load_app },
        qr/not found/i,
        'dies on missing file'
    );
};

# Test 13: Error on invalid module
subtest 'error on invalid module' => sub {
    my $runner = PAGI::Server::Runner->new;
    $runner->{argv} = ['PAGI::App::NonExistent12345'];

    like(
        dies { $runner->load_app },
        qr/Cannot find module/i,
        'dies on invalid module'
    );
};

# Test 14: Error on file that doesn't return coderef
subtest 'error on non-coderef file' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $bad_app = "$tmpdir/bad_app.pl";

    # Write a file that returns a hashref instead of coderef
    open my $fh, '>', $bad_app or die "Cannot write $bad_app: $!";
    print $fh "{ foo => 'bar' };\n";
    close $fh;

    my $runner = PAGI::Server::Runner->new;
    $runner->{app_spec} = $bad_app;

    like(
        dies { $runner->load_app },
        qr/must return a coderef/i,
        'dies on non-coderef'
    );
};

# Test 15: load_server constructs the configured server class
subtest 'load_server creates server' => sub {
    my $runner = PAGI::Server::Runner->new(server => 'PAGITest::FakeServer', port => 0, quiet => 1);
    $runner->{app} = sub { };
    my $fake = $runner->load_server;

    isa_ok($fake, ['PAGITest::FakeServer'], 'load_server constructs the configured class');
    is($fake->{options}{app}, $runner->{app}, 'app passed to constructor');

    # SSL config must be forwarded unchanged — whether the server honours it
    # (cert-file validation etc.) is tested in PAGI-Server's own suite.
    my $ssl_runner = PAGI::Server::Runner->new(
        server         => 'PAGITest::FakeServer',
        quiet          => 1,
        server_options => { ssl => { cert_file => 'c', key_file => 'k' } },
    );
    $ssl_runner->{app} = sub { };
    my $ssl_fake = $ssl_runner->load_server;
    is($ssl_fake->{options}{ssl}, { cert_file => 'c', key_file => 'k' },
        'ssl config passed through unchanged');
};

# Tests 16-19 (load_server dies without app, integration: server responds to
# requests, integration: module-based app serves files, SSL options validation)
# have been relocated to the PAGI-Server distribution because they exercise
# PAGI::Server internals or require a real socket.  Saved verbatim to
# /tmp/pagi-moved-subtests.pl for that relocation task.

# Test 20: help flag
subtest 'help flag sets show_help' => sub {
    my $runner = PAGI::Server::Runner->new;
    $runner->parse_options('--help');

    ok($runner->{show_help}, 'show_help is set');
};

# Test 21: production CLI options parsing
subtest 'production CLI options parsing' => sub {
    my $runner = PAGI::Server::Runner->new;
    $runner->parse_options(
        '-D',
        '--pid', '/tmp/test.pid',
        '--user', 'nobody',
        '--group', 'nogroup',
    );

    is($runner->{daemonize}, 1, '--daemonize parsed');
    is($runner->{pid_file}, '/tmp/test.pid', '--pid parsed');
    is($runner->{user}, 'nobody', '--user parsed');
    is($runner->{group}, 'nogroup', '--group parsed');
};

# Test 22: _drop_privileges validation
subtest '_drop_privileges validation' => sub {
    # Skip on Windows - getpwnam/getgrnam not available
    if ($^O eq 'MSWin32') {
        skip_all 'User/group privilege tests not supported on Windows';
    }

    # Test 1: Returns early if neither user nor group specified
    my $runner1 = PAGI::Server::Runner->new(port => 0, quiet => 1);
    ok(lives { $runner1->_drop_privileges }, '_drop_privileges returns early when no user/group');

    # Test 2: Requires root for --user
    my $runner2 = PAGI::Server::Runner->new(
        user => 'nobody',
        port => 0,
        quiet => 1,
    );

    if ($> == 0) {
        # Running as root - test should validate user exists
        my $runner3 = PAGI::Server::Runner->new(
            user => 'nonexistent_user_12345',
            port => 0,
            quiet => 1,
        );
        like(
            dies { $runner3->_drop_privileges },
            qr/Unknown user/,
            'rejects unknown user (as root)'
        );
    } else {
        # Not root - should require root
        like(
            dies { $runner2->_drop_privileges },
            qr/Must run as root/,
            'requires root for --user'
        );
    }

    # Test 3: Requires root for --group
    my $runner4 = PAGI::Server::Runner->new(
        group => 'nogroup',
        port => 0,
        quiet => 1,
    );

    if ($> == 0) {
        # Running as root - test should validate group exists
        my $runner5 = PAGI::Server::Runner->new(
            group => 'nonexistent_group_12345',
            port => 0,
            quiet => 1,
        );
        like(
            dies { $runner5->_drop_privileges },
            qr/Unknown group/,
            'rejects unknown group (as root)'
        );
    } else {
        # Not root - should require root
        like(
            dies { $runner4->_drop_privileges },
            qr/Must run as root/,
            'requires root for --group'
        );
    }
};

# Test 23: _drop_privileges method exists
subtest '_drop_privileges method exists' => sub {
    my $runner = PAGI::Server::Runner->new;
    ok($runner->can('_drop_privileges'), '_drop_privileges method exists');
};

# Test 24: mode() method
subtest 'mode detection' => sub {
    # Test explicit env
    my $runner1 = PAGI::Server::Runner->new(env => 'production');
    is($runner1->mode, 'production', 'explicit env wins');

    # Test PAGI_ENV
    local $ENV{PAGI_ENV} = 'development';
    my $runner2 = PAGI::Server::Runner->new;
    is($runner2->mode, 'development', 'PAGI_ENV used when no explicit env');

    # With explicit env, PAGI_ENV is ignored
    my $runner3 = PAGI::Server::Runner->new(env => 'none');
    is($runner3->mode, 'none', 'explicit env overrides PAGI_ENV');
};

# Test 25: -E flag parsing
subtest '-E flag parsing' => sub {
    my $runner = PAGI::Server::Runner->new;
    $runner->parse_options('-E', 'production', 'app.pl');

    is($runner->{env}, 'production', '-E parsed');
    is($runner->mode, 'production', 'mode returns production');
};

# Test 26: remaining args after runner options go to argv
subtest 'remaining args go to argv' => sub {
    my $runner = PAGI::Server::Runner->new;
    $runner->parse_options(
        '-p', '8080',
        'app.pl',
        'root=/tmp',
    );

    is($runner->{port}, 8080, 'runner option parsed');
    # Remaining non-option args go to argv
    is($runner->{argv}[0], 'app.pl', 'app spec in argv');
    is($runner->{argv}[1], 'root=/tmp', 'app arg in argv');
};

# Test 27: --no-default-middleware flag
subtest '--no-default-middleware flag' => sub {
    my $runner = PAGI::Server::Runner->new;
    $runner->parse_options('--no-default-middleware', 'app.pl');

    is($runner->{default_middleware}, 0, '--no-default-middleware sets to 0');
};

# Test 28: -e inline code
subtest '-e inline code' => sub {
    my $runner = PAGI::Server::Runner->new;
    # Use a proper PAGI-style app signature
    my $code = 'sub { my ($scope, $receive, $send) = @_; $send->({type => "http.response.start", status => 200, headers => []}); $send->({type => "http.response.body", body => "Hello"}) }';
    $runner->parse_options('-e', $code);

    is($runner->{eval}, $code, '-e code stored');

    my $app = $runner->load_app;
    ok(ref $app eq 'CODE', '-e returns coderef');
    is($runner->{app_spec}, '-e', 'app_spec is -e');
};

# Test 29: -M module loading (requires PAGI-Tools for PAGI::App::File)
subtest '-M module loading' => sub {
    my $runner = PAGI::Server::Runner->new;
    $runner->parse_options('-M', 'PAGI::App::File', '-e', 'PAGI::App::File->new(root => ".")->to_app');

    # Option parsing is pure string handling — no module load required.
    is(scalar @{$runner->{modules}}, 1, 'one module stored');
    is($runner->{modules}[0], 'PAGI::App::File', 'correct module');

    # Actually loading the -M module + running the -e code needs the app present.
    SKIP: {
        skip 'PAGI::App::File not available (install PAGI-Tools >= 0.002000)', 1
            unless eval { require PAGI::Tools; PAGI::Tools->VERSION(0.002000); require PAGI::App::File; 1 };
        my $app = $runner->load_app;
        ok(ref $app eq 'CODE', '-M/-e returns coderef');
    }
};

# Test 30: cuddled -M option (requires PAGI-Tools for PAGI::App::File)
subtest 'cuddled -M option' => sub {
    # Pure option parsing of the cuddled -MFoo form; no module load required.
    my $runner = PAGI::Server::Runner->new;
    $runner->parse_options('-MPAGI::App::File', '-e', 'PAGI::App::File->new(root => ".")->to_app');

    is(scalar @{$runner->{modules}}, 1, 'cuddled module parsed');
    is($runner->{modules}[0], 'PAGI::App::File', 'correct cuddled module');
};

# Test 31: -e error handling
subtest '-e error handling' => sub {
    my $runner = PAGI::Server::Runner->new;
    $runner->parse_options('-e', '{ not => "a coderef" }');

    like(
        dies { $runner->load_app },
        qr/must return a coderef/,
        '-e dies if not coderef'
    );
};

# Test 32: PAGI_ENV is exported after mode resolution
subtest 'PAGI_ENV exported after mode resolution' => sub {
    # Clear PAGI_ENV first
    local $ENV{PAGI_ENV};

    # Simulate what run() does: parse options then set PAGI_ENV
    my $runner = PAGI::Server::Runner->new;
    $runner->parse_options('-E', 'production', 'app.pl');

    # This is what run() does after parse_options
    $ENV{PAGI_ENV} = $runner->mode;

    is($ENV{PAGI_ENV}, 'production', 'PAGI_ENV set to resolved mode');

    # Test with TTY auto-detection (no -E flag)
    delete $ENV{PAGI_ENV};
    my $runner2 = PAGI::Server::Runner->new;
    $runner2->parse_options('app.pl');
    $ENV{PAGI_ENV} = $runner2->mode;

    # Should be development (if TTY) or production (if not)
    # In test environment, this depends on how tests are run
    ok(defined $ENV{PAGI_ENV}, 'PAGI_ENV set even with auto-detection');
    like($ENV{PAGI_ENV}, qr/^(development|production)$/, 'PAGI_ENV is valid mode');
};

# Test: Runner accepts server_options hashref
subtest 'server_options hashref accepted by constructor' => sub {
    my $runner = PAGI::Server::Runner->new(
        port          => 0,
        quiet         => 1,
        server_options => { workers => 4, timeout => 30 },
    );

    is(ref $runner->{server_options}, 'HASH', 'server_options is a hashref');
    is($runner->{server_options}{workers}, 4, 'workers preserved');
    is($runner->{server_options}{timeout}, 30, 'timeout preserved');
};

# Test: server_options passed via parse_options args
subtest 'server_options passed via parse_options' => sub {
    my $runner = PAGI::Server::Runner->new;
    $runner->parse_options(
        '-p', '8080',
        'server_options', { workers => 2 },
        'app.pl',
    );

    is(ref $runner->{server_options}, 'HASH', 'server_options is hashref');
    is($runner->{server_options}{workers}, 2, 'workers from server_options');
    is($runner->{port}, 8080, 'port still parsed');
    is($runner->{argv}[0], 'app.pl', 'app in argv');
};

# Test: load_server passes server_options through to the server constructor
subtest 'load_server passes server_options' => sub {
    my $runner = PAGI::Server::Runner->new(
        server         => 'PAGITest::FakeServer',
        port           => 0,
        quiet          => 1,
        server_options => { timeout => 42 },
    );
    $runner->{app} = sub { };
    my $fake = $runner->load_server;

    isa_ok($fake, ['PAGITest::FakeServer'], 'constructed configured class');
    is($fake->{options}{timeout}, 42, 'server_options threaded into constructor');
};

# Test: load_server with socket option omits host/port from constructor args
subtest 'load_server with socket option omits host/port' => sub {
    my $runner = PAGI::Server::Runner->new(
        server         => 'PAGITest::FakeServer',
        quiet          => 1,
        server_options => { socket => '/tmp/pagi-test.sock' },
    );
    $runner->{app} = sub { };
    my $fake = $runner->load_server;

    ok(!exists $fake->{options}{host}, 'host omitted when socket given');
    ok(!exists $fake->{options}{port}, 'port omitted when socket given');
    is($fake->{options}{socket}, '/tmp/pagi-test.sock', 'socket passed through');
};

# Test: load_server with listen option omits host/port from constructor args
subtest 'load_server with listen option omits host/port' => sub {
    my $listen = [ { host => '127.0.0.1', port => 8080 } ];
    my $runner = PAGI::Server::Runner->new(
        server         => 'PAGITest::FakeServer',
        quiet          => 1,
        server_options => { listen => $listen },
    );
    $runner->{app} = sub { };
    my $fake = $runner->load_server;

    ok(!exists $fake->{options}{host}, 'host omitted when listen given');
    ok(!exists $fake->{options}{port}, 'port omitted when listen given');
    is($fake->{options}{listen}, $listen, 'listen passed through');
};

# Version output must reflect the selected server class, not assume
# PAGI::Server (Runner is server-agnostic; see PAGI::Spec::Server)
subtest 'version output is server-agnostic' => sub {
    my $runner = PAGI::Server::Runner->new(server => 'PAGITest::FakeServer');

    my $out = '';
    {
        open my $fh, '>', \$out or die "Cannot open scalar handle: $!";
        local *STDOUT = $fh;
        $runner->_show_version;
    }

    like($out, qr/PAGITest::FakeServer 0\.001/, 'reports selected server class and its version');
    unlike($out, qr/PAGI::Server\b/, 'does not hardcode PAGI::Server');

    # The CLI path must work too: -s CLASS --version goes through
    # parse_options, which must store the server class before its
    # version early-return
    my $cli_runner = PAGI::Server::Runner->new;
    $cli_runner->parse_options('-s', 'PAGITest::FakeServer', '--version');

    my $cli_out = '';
    {
        open my $fh, '>', \$cli_out or die "Cannot open scalar handle: $!";
        local *STDOUT = $fh;
        $cli_runner->_show_version;
    }

    like($cli_out, qr/PAGITest::FakeServer 0\.001/, '-s CLASS --version reports the selected class');

    # A bogus/unloadable server class must degrade to 'unknown', not crash
    my $bogus_runner = PAGI::Server::Runner->new(server => 'PAGITest::DoesNotExist');
    my $bogus_out = '';
    {
        open my $fh, '>', \$bogus_out or die "Cannot open scalar handle: $!";
        local *STDOUT = $fh;
        $bogus_runner->_show_version;
    }
    like($bogus_out, qr/PAGITest::DoesNotExist unknown/, 'missing server class degrades to unknown');
};

done_testing;
