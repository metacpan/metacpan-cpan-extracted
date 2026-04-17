#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use JSON::PP;
use POSIX ":sys_wait_h";
use File::Temp qw(tempdir);

use lib "$FindBin::Bin/../lib";

plan skip_all => "integration test requires TS_LIB_PATH"
    unless $ENV{TS_LIB_PATH};

my $testenv_bin = "$FindBin::Bin/../testenv/testenv";

plan skip_all => "integration test requires testenv/testenv"
    unless -x $testenv_bin;

plan skip_all => "libtailscalers.so not found in TS_LIB_PATH"
    unless -f "$ENV{TS_LIB_PATH}/libtailscalers.so";

$ENV{TS_RS_EXPERIMENT} = "this_is_unstable_software";
$ENV{RUST_LOG} //= "error";

plan tests => 5;

# --- Start test environment ---
diag "Starting testenv (Go testcontrol + DERP + STUN)...";
my $testenv_pid = open(my $testenv_fh, "-|", $testenv_bin)
    or die "Failed to start testenv: $!";
my $config_line = <$testenv_fh>;
chomp $config_line;
my $config = decode_json($config_line);
my $control_url = $config->{control_url};
my $auth_key    = $config->{auth_key};
ok($control_url, "testenv started, control_url=$control_url");

END {
    if ($testenv_pid) { kill 'TERM', $testenv_pid; waitpid($testenv_pid, 0) }
}

my $tmpdir = tempdir(CLEANUP => 1);
my $lib_dir = "$FindBin::Bin/../lib";

require Tailscale;

# --- Create client node ---
diag "Creating client node...";
my $client = Tailscale->new(
    config_path => "$tmpdir/client.json",
    auth_key    => $auth_key,
    control_url => $control_url,
    hostname    => "client",
);
my $client_ip = $client->ipv4_addr();
ok($client_ip, "client got IPv4: $client_ip");

# --- Start server subprocess that handles an HTTP request ---
# This tests the full stack: control plane registration, DERP relay,
# TCP listen/accept/connect/send/recv, and HTTP parsing/response.
my $server_ready = "$tmpdir/server-ready";

my $server_pid;
if (($server_pid = fork()) == 0) {
    exec("perl", "-e", <<"SCRIPT") or die "exec: $!";
use lib '$lib_dir';
use Tailscale;
use HTTP::Response;
\$ENV{TS_LIB_PATH} = '$ENV{TS_LIB_PATH}';
\$ENV{RUST_LOG} = 'error';

my \$ts = Tailscale->new(
    config_path => '$tmpdir/server.json',
    auth_key    => '$auth_key',
    control_url => '$control_url',
    hostname    => 'server',
);
my \$ip = \$ts->ipv4_addr();
sleep 3; # Wait for DERP

my \$listener = \$ts->tcp_listen(9100);
open my \$f, '>', '$server_ready'; print \$f \$ip; close \$f;

# Accept one connection and handle it as HTTP.
my \$stream = \$listener->accept();

# Read HTTP request.
my \$raw = "";
while (1) {
    my \$chunk = \$stream->recv(4096);
    last unless defined \$chunk;
    \$raw .= \$chunk;
    last if \$raw =~ /\\r\\n\\r\\n/;
}

# Parse request line.
my (\$method, \$uri) = \$raw =~ m{^(\\S+)\\s+(\\S+)};
\$method //= "?";
\$uri //= "?";

# Build and send HTTP response.
my \$body = "Hello from Perl on Tailscale!\\nMethod: \$method\\nURI: \$uri\\n";
my \$resp = "HTTP/1.0 200 OK\\r\\n"
          . "Content-Type: text/plain\\r\\n"
          . "Content-Length: " . length(\$body) . "\\r\\n"
          . "Connection: close\\r\\n"
          . "\\r\\n"
          . \$body;
\$stream->send_all(\$resp);
\$stream->close();
\$listener->close();
\$ts->close();
SCRIPT
}

diag "Waiting for server...";
for (1..45) { last if -f $server_ready; sleep 1 }
die "server not ready" unless -f $server_ready;
open my $rf, '<', $server_ready;
my $server_ip = <$rf>;
close $rf;
chomp $server_ip;
ok($server_ip, "server got IPv4: $server_ip");
sleep 3; # peer discovery

# --- Test: HTTP request/response over tailnet ---
diag "Sending HTTP GET to $server_ip:9100 over tailnet...";
my ($http_ok, $body_ok) = (0, 0);
eval {
    local $SIG{ALRM} = sub { die "timeout\n" };
    alarm 30;
    my $stream = $client->tcp_connect("$server_ip:9100");
    $stream->send_all("GET /hello HTTP/1.0\r\nHost: $server_ip\r\nConnection: close\r\n\r\n");
    my $response = "";
    while (defined(my $chunk = $stream->recv(4096))) {
        $response .= $chunk;
    }
    $stream->close();
    alarm 0;
    diag "Response:\n$response";
    $http_ok = ($response =~ /^HTTP\/1\.0 200/);
    $body_ok = ($response =~ /Hello from Perl on Tailscale/);
};
warn "HTTP: $@" if $@;

# Kill the server child -- its $ts->close() can hang on DERP teardown.
kill 'KILL', $server_pid if $server_pid;
waitpid($server_pid, 0) if $server_pid;

ok($http_ok, "HTTP response status 200");
ok($body_ok, "HTTP response body contains expected text");

done_testing();

# Prevent Perl global destruction from calling DESTROY on Tailscale objects,
# which can hang on DERP teardown.  Undef them without closing so the
# destructor is a no-op (the process is about to exit anyway).
$client->{_closed} = 1 if $client;
undef $client;

# Kill testenv and exit cleanly.
if ($testenv_pid) {
    kill 'TERM', $testenv_pid;
    waitpid($testenv_pid, 0);
    $testenv_pid = undef;
}
