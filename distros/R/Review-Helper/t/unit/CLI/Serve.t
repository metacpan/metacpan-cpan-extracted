# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use File::Temp qw/tempdir/;
use POSIX();
use HTTP::Server::PSGI;
use Time::HiRes qw/time/;
use HTTP::Tiny;
use Plack::Test;
use HTTP::Request::Common qw/GET/;

use TestRepo qw/make_repo commit_file/;
use TestCLI qw/cli/;
use IO::Socket::IP();
use Sys::Hostname();
use Review::Helper::CLI::Serve;
use Review::Helper::DB;
use Review::Helper::VCS;
use Review::Helper::Server;
use Review::Helper::Util qw/json_decode/;

# A developer's own settings must not reach these servers.
delete $ENV{$_} for qw/REVIEW_HELPER_PORT_COMMAND REVIEW_HELPER_LISTEN REVIEW_HELPER_ALLOW_HOSTS/;

my $dir      = make_repo();
my $revision = commit_file($dir, 'Start', 'README' => "hello\n");
my $repo     = Review::Helper::VCS->detect($dir);
my $file     = $repo->state_dir . '/serve.sqlite';
my $db       = Review::Helper::DB->create($file, title => 'Served');
$db->dbh->do('INSERT INTO iteration (number, base, head, pin, created) VALUES (1, ?, ?, ?, 1)', undef, $revision, $revision, 'refs/review-helper/x/1');

subtest port_command => sub {
    my $bin    = tempdir(CLEANUP => 1);
    my $script = sub ($name, $body) {
        open(my $fh, '>', "$bin/$name") or die "Cannot write '$bin/$name': $!";
        print $fh "#!/bin/sh\n$body\n";
        close($fh)                or die "Cannot write '$bin/$name': $!";
        chmod(0755, "$bin/$name") or die "Cannot chmod '$bin/$name': $!";
        return "$bin/$name";
    };
    my $echo = $script->('echo-port', 'echo "$@"');
    my $fail = $script->('fail',      'exit 3');
    my $word = $script->('word',      'echo eighty');

    local $ENV{REVIEW_HELPER_PORT_COMMAND};
    my $class = 'Review::Helper::CLI::Serve';
    is($class->pick_port(undef, undef),        0,    'any free port by default');
    is($class->pick_port(8123,  undef),        8123, '--port');
    is($class->pick_port(undef, "$echo 8124"), 8124, '--port-command, split into arguments');

    $ENV{REVIEW_HELPER_PORT_COMMAND} = "$echo 8126";
    is($class->pick_port(undef, undef),        8126, 'REVIEW_HELPER_PORT_COMMAND is the default');
    is($class->pick_port(8123,  undef),        8123, '--port wins over it');
    is($class->pick_port(undef, "$echo 8127"), 8127, '--port-command wins over it');

    like(dies { $class->pick_port(8123, "$echo 1") },         qr/Give --port or --port-command, not both/,       'not both');
    like(dies { $class->run_port_command("$bin/none") },      qr{Cannot run port command '\Q$bin\E/none': },     'a missing command');
    like(dies { $class->run_port_command('echo${IFS}8123') }, qr/Cannot run port command 'echo\$\{IFS\}8123': /, 'a one-word command is not run through a shell');
    like(dies { $class->run_port_command($fail) },            qr/failed with exit code 3/,                       'a failing command');
    like(dies { $class->run_port_command($word) },            qr/printed 'eighty', not a port number/,           'output that is not a port');
    like(dies { $class->run_port_command("$echo 70000") },    qr/printed '70000', not a port number/,            'a port out of range');
    {
        local *STDOUT;
        open(STDOUT, '>', \my $mem) or die "open: $!";
        is($class->run_port_command("$echo 8128"), 8128,  'the port is read when STDOUT is not descriptor 1');
        is($mem,                                   undef, 'and not written to the in-memory STDOUT');
    }
    {
        my $save = POSIX::dup(1) // die "dup: $!";
        STDOUT->flush;
        POSIX::close(1);
        my $port = eval { $class->run_port_command("$echo 8129") };
        my $err  = $@;
        POSIX::dup2($save, 1) // die "dup2: $!";
        POSIX::close($save);
        is([$port, $err], [8129, ''], 'and when descriptor 1 is closed');
    }
};

my $class = 'Review::Helper::CLI::Serve';

# A listening socket on $addr, or undef when this machine cannot bind it.
sub can_bind($addr) {
    eval { $class->listen_socket(0, $addr) }
}

subtest listen_socket => sub {
    my $socket = $class->listen_socket(0);
    is($socket->sockhost, '127.0.0.1', 'loopback only by default');
    ok($socket->sockport > 0, 'port 0 picks a free port');

    is($class->listen_socket(0, '0.0.0.0')->sockhost,   '0.0.0.0',                           'every IPv4 interface');
    is($class->listen_socket(0, 'localhost')->sockhost, match(qr/\A(?:127\.0\.0\.1|::1)\z/), 'a host name is resolved');
    like(dies { $class->listen_socket(0, 'no-such-host.invalid') }, qr/\ACannot listen on no-such-host\.invalid port 0: /, 'an unknown name');

    if (my $other = can_bind('127.0.0.2')) { is($other->sockhost, '127.0.0.2', 'a given address') }
    if (my $v6    = can_bind('::1'))       { is($v6->sockhost,    '::1',       'an IPv6 address') }

    ok($class->is_wildcard($_),  "$_ is a wildcard")  for qw/0.0.0.0 ::/;
    ok(!$class->is_wildcard($_), "$_ is no wildcard") for qw/127.0.0.1 10.0.0.1 ::1/;

    my $token = $class->new_token;
    like($token, qr/\A[0-9a-f]{64}\z/, 'a token is 32 random bytes in hex');
    isnt($class->new_token, $token, 'a new one each time');

    is([$class->urls('localhost', '127.0.0.1', 80)], ['http://127.0.0.1:80/'],                                    'loopback: the bound address');
    is([$class->urls('::1', '::1', 80)],             ['http://[::1]:80/'],                                        'in brackets for IPv6');
    is([$class->urls('dev1', '10.0.0.1', 80)],       ['http://dev1:80/'],                                         'a specific address: as given, and no loopback URL');
    is([$class->urls('fe80::1', 'fe80::1', 80)],     ['http://[fe80::1]:80/'],                                    'a specific IPv6 address');
    is([$class->urls('0.0.0.0', '0.0.0.0', 80)],     ['http://' . $class->fqdn . ':80/', 'http://127.0.0.1:80/'], 'a wildcard: the FQDN, then loopback');
    is([$class->urls('::', '::', 80)],               ['http://' . $class->fqdn . ':80/', 'http://[::1]:80/'],     'an IPv6 wildcard');

    my @names = $class->network_names('0.0.0.0', '0.0.0.0');
    ok((grep { $_ eq Sys::Hostname::hostname() } @names), 'the hostname is a network name');
    ok((grep { $_ eq $class->fqdn } @names),              'and the FQDN');
    ok(!(grep { $_ eq '0.0.0.0' } @names),                'a wildcard is not');
    @names = $class->network_names('dev1', '10.9.8.7');
    ok((grep { $_ eq 'dev1' } @names),     'the name listened on is');
    ok((grep { $_ eq '10.9.8.7' } @names), 'and the address bound');
};

subtest open_browser => sub {
    my $bin = tempdir(CLEANUP => 1);
    for my $name (qw/xdg-open open/) {
        open(my $fh, '>', "$bin/$name") or die "Cannot write '$bin/$name': $!";
        # Like an opener that starts the browser and waits for it to exit.
        print $fh "#!/bin/sh\necho \"$name \$*\" > '$bin/ran.tmp'\nmv '$bin/ran.tmp' '$bin/ran'\nexec sleep 5\n";
        close($fh)                or die "Cannot write '$bin/$name': $!";
        chmod(0755, "$bin/$name") or die "Cannot chmod '$bin/$name': $!";
    }
    local $ENV{PATH} = "$bin:$ENV{PATH}";

    my $ran = sub {
        my $until = time + 10;
        Time::HiRes::sleep(0.05) until -e "$bin/ran" || time > $until;
        open(my $fh, '<', "$bin/ran") or return undef;
        my $line = <$fh>;
        unlink("$bin/ran");
        return $line;
    };

    {
        local $^O = 'linux';
        my $start = time;
        is(Review::Helper::CLI::Serve->open_browser('http://x/'), 1, 'opened on Linux');
        ok(time - $start < 3, 'without waiting for the opener to finish');
        is($ran->(), "xdg-open http://x/\n", 'with xdg-open');
    }
    {
        local $^O = 'darwin';
        Review::Helper::CLI::Serve->open_browser('http://y/');
        is($ran->(), "open http://y/\n", 'with open on macOS');
    }
    {
        local $^O = 'MSWin32';
        is(Review::Helper::CLI::Serve->open_browser('http://z/'), 0, 'not elsewhere');
        Time::HiRes::sleep(0.2);
        ok(!-e "$bin/ran", 'nothing run');
    }
    {
        local $^O = 'linux';
        local $ENV{PATH} = tempdir(CLEANUP => 1);
        my $log = "$bin/stderr";
        open(my $saved, '>&', \*STDERR) or die "Cannot save STDERR: $!";
        open(STDERR,    '>',  $log)     or die "Cannot redirect STDERR: $!";
        my $got = Review::Helper::CLI::Serve->open_browser('http://x/');
        open(STDERR, '>&', $saved) or die "Cannot restore STDERR: $!";
        is($got, 1, 'started');

        my $until = time + 10;
        Time::HiRes::sleep(0.05) until -s $log || time > $until;
        open(my $fh, '<', $log) or die "Cannot read '$log': $!";
        like(join('' => <$fh>), qr/Could not run 'xdg-open'/, 'a missing opener is reported');
    }
};

subtest run => sub {
    local $ENV{REVIEW_HELPER_REVIEWER};
    my ($app, $socket);
    my $server = mock 'HTTP::Server::PSGI' => (override => [run => sub ($self, $psgi) { ($app, $socket) = ($psgi, $self->{listen_sock}) }]);
    my $opened;
    my $open = mock 'Review::Helper::CLI::Serve' => (override => [open_browser => sub ($class, $url) { $opened = $url }]);

    my ($exit, $out, $err) = cli($dir, 'serve', $file);
    is([$exit, $err], [0, ''], 'serve runs');
    like($out, qr{\Ahttp://127\.0\.0\.1:(\d+)/\n\z}, 'prints the plain URL');
    my ($port) = $out =~ m{:(\d+)/};
    is([$socket->sockhost, $socket->sockport], ['127.0.0.1', $port], 'serves on the printed address');
    is($opened,                                undef,                'no browser without --open');

    my $res = Plack::Test->create($app)->request(GET "http://127.0.0.1:$port/");
    is($res->code, 200, 'the URL opens the page');

    my $identity = sub { json_decode(Plack::Test->create($app)->request(GET "http://127.0.0.1:$port/api/review")->content)->{identity} };
    is($identity->()->{reviewer}, 'Tester <tester@example.com>', "the reviewer defaults to the repository's git user");
    ($exit, $out) = cli($dir, 'serve', '--reviewer', 'Ann', $file);
    ($port) = $out =~ m{:(\d+)/};
    is($identity->()->{reviewer}, 'Ann', '--reviewer names the reviewer');

    ($exit, $out) = cli($dir, $file, '--open');
    is($exit,       0,    'a file alone means serve');
    is("$opened\n", $out, '--open opens the printed URL');

    my $free = Review::Helper::CLI::Serve->listen_socket(0)->sockport;
    ($exit, $out) = cli($dir, 'serve', '--port', $free, $file);
    like($out, qr{:$free/}, '--port picks the port');

    $free = Review::Helper::CLI::Serve->listen_socket(0)->sockport;
    ($exit, $out, $err) = cli($dir, 'serve', '--port-command', "echo $free", $file);
    is([$exit, $out, $err], [0, "http://127.0.0.1:$free/\n", ''], '--port-command picks the port');
    ($exit, $out, $err) = cli($dir, 'serve', '--port-command', 'false', $file);
    is([$exit, $err], [1, "review-helper serve: Port command 'false' failed with exit code 1\n"], 'a failing port command is reported');

    ($exit, $out, $err) = cli($dir, 'serve');
    is([$exit, $err], [1, "review-helper serve: Usage: review-helper serve FILE [--port N | --port-command CMD] [--listen ADDR] [--allow-host NAME]... [--open] [--reviewer NAME]\n"], 'needs a file');
    ($exit, $out, $err) = cli($dir, 'serve', $file, '--port', 'x');
    is([$exit, $err], [1, "review-helper serve: Invalid port 'x'\n"], 'bad port');
    ($exit, $out, $err) = cli($dir, "$dir/none.sqlite");
    like($err, qr/No such review file/, 'missing file');
};

subtest listen => sub {
    local $ENV{REVIEW_HELPER_REVIEWER};
    my ($app, $socket);
    my $server = mock 'HTTP::Server::PSGI' => (override => [run => sub ($self, $psgi) { ($app, $socket) = ($psgi, $self->{listen_sock}) }]);
    my $opened;
    my $open = mock 'Review::Helper::CLI::Serve' => (override => [open_browser => sub ($class, $url) { $opened = $url }]);

    my $code = sub ($name) {
        my $req = GET 'http://127.0.0.1/api/review';
        $req->header(Host => $name);
        return Plack::Test->create($app)->request($req)->code;
    };
    my $warning = qr/\Areview-helper: listening on (\S+), beyond this machine: anyone with the token URL above can read this review and post feedback, and anyone on this machine can without it; keep the URL private\.\n\z/;

    if (can_bind('127.0.0.2')) {
        my ($exit, $out, $err) = cli($dir, 'serve', '--listen', '127.0.0.2', $file);
        my ($port) = $out =~ m{:(\d+)/};
        is([$exit, $out, $err],                [0, "http://127.0.0.2:$port/\n", ''], 'a loopback address: its URL, no token and no warning');
        is($socket->sockhost,                  '127.0.0.2',                          'bound there');
        is($code->(Sys::Hostname::hostname()), 403,                                  'and only loopback names are accepted');
    }

    my ($exit, $out, $err) = cli($dir, 'serve', '--listen', '0.0.0.0', '--allow-host', 'alias.example.com', '--open', $file);
    my ($port)  = $out =~ m{:(\d+)/};
    my ($token) = $out =~ m{\?token=([0-9a-f]{64})\n};
    my $fqdn    = Review::Helper::CLI::Serve->fqdn;
    is([$exit, $out], [0, "http://$fqdn:$port/?token=$token\nhttp://127.0.0.1:$port/\n"], 'every interface: the token URL for other machines, then the loopback one');

    my $remote = sub ($url, @headers) {
        my $req = GET $url, @headers;
        $req->header(Host => "$fqdn:$port");
        return Plack::Test->create(sub ($env) {
            $app->({%$env, REMOTE_ADDR => '192.0.2.7', SERVER_PORT => $port});
        })->request($req);
    };
    is($remote->("http://$fqdn:$port/api/review")->code, 401, 'another machine needs the token');
    my $res = $remote->("http://$fqdn:$port/?token=$token");
    is($res->code, 303, 'the printed token URL logs in');
    my ($cookie) = ($res->header('Set-Cookie') // '') =~ m/\A([^;]+)/;
    is($remote->("http://$fqdn:$port/api/review", Cookie => $cookie)->code, 200, 'and its cookie lets that machine in');

    like($err, $warning, 'with a warning on stderr');
    is($socket->sockhost,                  '0.0.0.0',                 'bound to every IPv4 interface');
    is($opened,                            "http://127.0.0.1:$port/", '--open opens the loopback URL');
    is($code->("$fqdn:$port"),             200,                       'the FQDN is accepted');
    is($code->(Sys::Hostname::hostname()), 200,                       'the hostname is accepted');
    is($code->('alias.example.com'),       200,                       '--allow-host names are accepted');
    is($code->("127.0.0.1:$port"),         200,                       'loopback still is');
    is($code->('evil.example.com'),        403,                       'other names are refused');
    is($code->('0.0.0.0'),                 403,                       'the wildcard is no host');

    {
        local $ENV{REVIEW_HELPER_LISTEN}      = '0.0.0.0';
        local $ENV{REVIEW_HELPER_ALLOW_HOSTS} = 'one.example.com, two.example.com';
        ($exit, $out, $err) = cli($dir, 'serve', '--allow-host', 'three.example.com', $file);
        is($socket->sockhost, '0.0.0.0', 'REVIEW_HELPER_LISTEN sets the address');
        like($err, $warning, 'and warns');
        is($code->($_), 200, "REVIEW_HELPER_ALLOW_HOSTS and --allow-host: $_ accepted") for qw/one.example.com two.example.com three.example.com/;

        ($exit, $out, $err) = cli($dir, 'serve', '--listen', '127.0.0.1', $file);
        is([$socket->sockhost, $err], ['127.0.0.1', ''], '--listen wins over it');
    }

    my $probe = IO::Socket::IP->new(PeerHost => '192.0.2.1', PeerPort => 9, Proto => 'udp');
    if (my $addr = $probe && $probe->sockhost) {
        ($exit, $out, $err) = cli($dir, 'serve', '--listen', $addr, $file);
        ($port) = $out =~ m{:(\d+)/};
        is([$exit, $out], [0, match(qr{\Ahttp://\Q$addr\E:$port/\?token=[0-9a-f]{64}\n\z})], 'a network address: only its token URL, since loopback is not served');
        like($err, $warning, 'with a warning');
        is($socket->sockhost,      $addr, 'bound there');
        is($code->("$addr:$port"), 200,   'its address is accepted');
    }

    if (can_bind('::')) {
        ($exit, $out, $err) = cli($dir, 'serve', '--listen', '::', $file);
        ($port) = $out =~ m{:(\d+)/};
        like($out, qr{\Ahttp://\Q$fqdn\E:$port/\?token=[0-9a-f]{64}\nhttp://\[::1\]:$port/\n\z}, 'every IPv6 interface: the loopback URL is [::1]');
        is($socket->sockhost, '::', 'bound there');
        like($err, $warning, 'with a warning');
        is($code->("[::1]:$port"), 200, '[::1] is accepted');
    }
};

# A real server in a child process, spoken to over HTTP.
subtest http => sub {
    my $socket = Review::Helper::CLI::Serve->listen_socket(0);
    my $port   = $socket->sockport;
    my $app    = Review::Helper::Server->new(db_path => $file)->to_app;

    my $pid = fork // die "fork failed: $!";
    unless ($pid) {
        HTTP::Server::PSGI->new(listen_sock => $socket)->run($app);
        exit 0;
    }
    close($socket);

    my $http = HTTP::Tiny->new(max_redirect => 0, timeout => 10);
    my $base = "http://127.0.0.1:$port";

    my $res = $http->get("$base/api/review");
    is($res->{status},                                200,      'the API answers');
    is(json_decode($res->{content})->{review}{title}, 'Served', 'review JSON');

    kill('TERM', $pid);
    waitpid($pid, 0);
};

done_testing;
