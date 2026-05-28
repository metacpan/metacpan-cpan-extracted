package RelayMockTest;

# Test helper for the porting-sdk mock_relay WebSocket server.
#
# Mirrors MockTest.pm but for RELAY:
# - Probes http://127.0.0.1:9780/__mock__/health to find/spawn mock-relay
#   (WS plane on 8780, HTTP control plane on 9780).
# - Reuses MockTest's adjacency walk to find porting-sdk/test_harness/mock_relay
#   and prepends to PYTHONPATH for `python -m mock_relay`.
# - Test pattern:
#       my $client = RelayMockTest::client(contexts => ["default"]);
#       $client->connect;  # combined connect_ws + authenticate
#       ... drive SDK ...
#       my $entry = RelayMockTest::journal_last();
#       is($entry->{method}, "signalwire.connect", "...");
#
# Port 8780/9780 reserved for the Perl rollout.

use strict;
use warnings;

use HTTP::Tiny;
use JSON qw(encode_json decode_json);
use POSIX ();
use Time::HiRes qw(sleep time);
use IPC::Open3 ();
use Symbol ();
use IO::Handle ();
use File::Spec ();
use Cwd ();
use Config ();

use SignalWire::Relay::Client;

our $VERSION = '0.01';

our $WS_PORT   = $ENV{MOCK_RELAY_PORT}      || 8780;
our $HTTP_PORT = $ENV{MOCK_RELAY_HTTP_PORT} || 9780;
our $HOST      = '127.0.0.1';
our $WS_URL    = "ws://$HOST:$WS_PORT";
our $HTTP_URL  = "http://$HOST:$HTTP_PORT";
our $RELAY_HOST = "$HOST:$WS_PORT";

our $PROJECT = 'test_proj';
our $TOKEN   = 'test_tok';

# Singleton state: spawn once per process.
our $_UA;
our $_MOCK_PID;
our $_ENSURED = 0;
our $_SKIP_REASON;

# Public API ---------------------------------------------------------------

# client(%opts) returns a SignalWire::Relay::Client pointed at the mock.
# Resets the journal/scenarios so every test starts clean.
# Does NOT connect — caller must $client->connect (or connect_ws+authenticate).
sub client {
    my %opts = @_;
    _ensure_server();
    if ($_SKIP_REASON) {
        if (eval { require Test::More; 1 }) {
            Test::More::plan(skip_all => "RelayMockTest: $_SKIP_REASON");
        }
        die "RelayMockTest: $_SKIP_REASON";
    }
    journal_reset();
    scenario_reset();

    my $client = SignalWire::Relay::Client->new(
        project  => $opts{project}  // $PROJECT,
        token    => $opts{token}    // $TOKEN,
        host     => $opts{host}     // $RELAY_HOST,
        scheme   => $opts{scheme}   // 'ws',
        path     => exists $opts{path} ? $opts{path} : '',
        contexts => $opts{contexts} // [],
        (exists $opts{agent} ? (agent => $opts{agent}) : ()),
    );
    return $client;
}

# Connect a fresh client (helper that does both connect_ws + authenticate).
sub connect_client {
    my ($client) = @_;
    my $ok = $client->connect_ws;
    die "RelayMockTest: connect_ws failed" unless $ok;
    my $r = $client->authenticate;
    die "RelayMockTest: authenticate failed" unless $r;
    return $r;
}

# journal_reset clears all journal entries on the mock.
sub journal_reset {
    _ensure_server();
    return if $_SKIP_REASON;
    # Retry: the mock may be transiently unreachable during cross-test
    # spawn races (HTTP::Tiny 599 = internal connect/timeout).
    my $resp;
    for my $i (1..10) {
        $resp = _ua()->post("$HTTP_URL/__mock__/journal/reset");
        last if $resp->{success};
        Time::HiRes::sleep(0.1);
    }
    die "journal_reset failed: $resp->{status}" unless $resp->{success};
}

# scenario_reset clears all queued scenarios on the mock.
sub scenario_reset {
    _ensure_server();
    return if $_SKIP_REASON;
    my $resp;
    for my $i (1..10) {
        $resp = _ua()->post("$HTTP_URL/__mock__/scenarios/reset");
        last if $resp->{success};
        Time::HiRes::sleep(0.1);
    }
    die "scenario_reset failed: $resp->{status}" unless $resp->{success};
}

# journal_all returns the list of all recorded frames since reset.
sub journal_all {
    _ensure_server();
    die "RelayMockTest: $_SKIP_REASON" if $_SKIP_REASON;
    my $resp = _ua()->get("$HTTP_URL/__mock__/journal");
    die "journal fetch failed: $resp->{status}" unless $resp->{success};
    return decode_json($resp->{content} || '[]');
}

# journal_last returns the most recently recorded frame.
sub journal_last {
    my @entries = @{ journal_all() };
    die "RelayMockTest: journal is empty - no SDK frames reached the mock"
        unless @entries;
    return $entries[-1];
}

# journal_recv returns inbound (SDK→server) frames, optionally filtered by method.
sub journal_recv {
    my (%opts) = @_;
    my @entries = grep { ($_->{direction} // '') eq 'recv' } @{ journal_all() };
    if (defined $opts{method}) {
        @entries = grep { ($_->{method} // '') eq $opts{method} } @entries;
    }
    return \@entries;
}

# journal_send returns outbound (server→SDK) frames, optionally filtered by event_type.
sub journal_send {
    my (%opts) = @_;
    my @entries = grep { ($_->{direction} // '') eq 'send' } @{ journal_all() };
    if (defined $opts{event_type}) {
        my $et = $opts{event_type};
        @entries = grep {
            my $f = $_->{frame} // {};
            my $p = $f->{params} // {};
            ($f->{method} // '') eq 'signalwire.event'
              && ref $p eq 'HASH'
              && ($p->{event_type} // '') eq $et;
        } @entries;
    }
    return \@entries;
}

# arm_method queues scripted post-RPC events for `method` (FIFO, consume-once).
sub arm_method {
    my ($method, $events) = @_;
    _ensure_server();
    return if $_SKIP_REASON;
    my $body = encode_json($events);
    my $resp = _ua()->post(
        "$HTTP_URL/__mock__/scenarios/$method",
        { content => $body, headers => { 'Content-Type' => 'application/json' } },
    );
    die "arm_method failed: $resp->{status} - $resp->{content}" unless $resp->{success};
}

# arm_dial queues a dial-dance scenario (winner state events + final dial event).
sub arm_dial {
    my (%kwargs) = @_;
    _ensure_server();
    return if $_SKIP_REASON;
    my $body = encode_json(\%kwargs);
    my $resp = _ua()->post(
        "$HTTP_URL/__mock__/scenarios/dial",
        { content => $body, headers => { 'Content-Type' => 'application/json' } },
    );
    die "arm_dial failed: $resp->{status} - $resp->{content}" unless $resp->{success};
}

# push a single signalwire.event (or other) frame to the SDK over WS.
sub push_frame {
    my ($frame, %opts) = @_;
    _ensure_server();
    return if $_SKIP_REASON;
    my $url = "$HTTP_URL/__mock__/push";
    if ($opts{session_id}) {
        $url .= "?session_id=$opts{session_id}";
    }
    my $body = encode_json({ frame => $frame });
    my $resp = _ua()->post(
        $url,
        { content => $body, headers => { 'Content-Type' => 'application/json' } },
    );
    die "push_frame failed: $resp->{status} - $resp->{content}" unless $resp->{success};
    return decode_json($resp->{content} // '{}');
}

# inbound_call pushes a calling.call.receive frame (and optional state events).
sub inbound_call {
    my (%opts) = @_;
    _ensure_server();
    return if $_SKIP_REASON;
    my %body = (
        from_number => $opts{from_number} // '+15551234567',
        to_number   => $opts{to_number}   // '+15559876543',
        context     => $opts{context}     // 'default',
        auto_states => $opts{auto_states} // ['created'],
        delay_ms    => $opts{delay_ms}    // 50,
    );
    $body{call_id} = $opts{call_id} if exists $opts{call_id};
    $body{session_id} = $opts{session_id} if exists $opts{session_id};
    my $payload = encode_json(\%body);
    my $resp = _ua()->post(
        "$HTTP_URL/__mock__/inbound_call",
        { content => $payload, headers => { 'Content-Type' => 'application/json' } },
    );
    die "inbound_call failed: $resp->{status} - $resp->{content}" unless $resp->{success};
    return decode_json($resp->{content} // '{}');
}

# scenario_play runs a scripted timeline (push/sleep/expect_recv ops).
sub scenario_play {
    my ($ops) = @_;
    _ensure_server();
    return if $_SKIP_REASON;
    my $body = encode_json($ops);
    my $ua = _ua();
    # scenario_play can take longer due to expect_recv waits; bump timeout.
    my $resp = $ua->post(
        "$HTTP_URL/__mock__/scenario_play",
        { content => $body, headers => { 'Content-Type' => 'application/json' } },
    );
    die "scenario_play failed: $resp->{status} - $resp->{content}" unless $resp->{success};
    return decode_json($resp->{content} // '{}');
}

# pump_for($client, $seconds) drives the client's recv loop for up to N seconds.
# Useful when a test pushes a server-initiated event and needs the SDK to
# process it before assertions.
sub pump_for {
    my ($client, $seconds, $until_cb) = @_;
    my $deadline = time() + $seconds;
    while (time() < $deadline) {
        eval { $client->_read_once };
        last if $until_cb && eval { $until_cb->($client) };
    }
}

# pump_until($client, $seconds, sub { ... predicate ... })
# Drive the recv loop until the predicate returns truthy or timeout expires.
sub pump_until {
    my ($client, $seconds, $cb) = @_;
    my $deadline = time() + $seconds;
    while (time() < $deadline) {
        return 1 if eval { $cb->() };
        eval { $client->_read_once };
    }
    return eval { $cb->() } ? 1 : 0;
}

# Internals ----------------------------------------------------------------

sub _ua {
    return $_UA ||= HTTP::Tiny->new( timeout => 30 );
}

# Walk this file's directory upward looking for an adjacent
# ../porting-sdk/test_harness/mock_relay/mock_relay/__init__.py.
# Returns the absolute path to the directory containing the Python package,
# or undef when no adjacent porting-sdk is reachable.
sub discover_porting_sdk_package {
    my ($name) = @_;
    my $here = Cwd::abs_path(__FILE__);
    return undef unless defined $here;
    my $dir = File::Spec->canonpath((File::Spec->splitpath($here))[1]);
    $dir =~ s{[/\\]$}{};
    while (1) {
        my $parent = File::Spec->canonpath(File::Spec->catdir($dir, File::Spec->updir));
        last if $parent eq $dir;
        my $candidate = File::Spec->catdir($parent, 'porting-sdk', 'test_harness', $name);
        my $init = File::Spec->catfile($candidate, $name, '__init__.py');
        return $candidate if -f $init;
        $dir = $parent;
    }
    return undef;
}

sub _ensure_server {
    return if $_ENSURED;
    $_ENSURED = 1;

    # Probe first.
    if (_probe_health()) {
        # Reuse whatever's already listening.
        return;
    }

    # Find porting-sdk/test_harness/mock_relay/ and put it on PYTHONPATH so
    # `python -m mock_relay` resolves without a prior `pip install -e ...`.
    my $pkg_dir = discover_porting_sdk_package('mock_relay');
    my $sep = $Config::Config{path_sep} // ':';
    my $existing = defined $ENV{PYTHONPATH} ? $ENV{PYTHONPATH} : '';
    local $ENV{PYTHONPATH} = defined $pkg_dir
        ? ($existing ne '' ? "$pkg_dir$sep$existing" : $pkg_dir)
        : $existing;

    my @cmd = (
        'python3', '-m', 'mock_relay',
        '--host', $HOST,
        '--ws-port',   $WS_PORT,
        '--http-port', $HTTP_PORT,
        '--log-level', 'error',
    );

    # fork() + redirect stderr/stdout to /dev/null in the child so the
    # mock's startup banner doesn't fill a closed-pipe and SIGPIPE the
    # process. IPC::Open3 leaves the child wired to perl's stderr/stdout
    # pipes; once we close them on the parent side the child dies on the
    # next write.
    my $pid = fork();
    if (!defined $pid) {
        $_SKIP_REASON = "fork failed: $!";
        return;
    }
    if ($pid == 0) {
        # Child.
        open(STDIN,  '<', '/dev/null');
        open(STDOUT, '>', '/dev/null');
        open(STDERR, '>', '/dev/null');
        # POSIX::setsid lets the parent's process group not propagate
        # SIGINT to the mock when a test runner Ctrl-C's.
        eval { POSIX::setsid() };
        exec(@cmd) or do {
            warn "exec failed: $!";
            POSIX::_exit(127);
        };
    }
    $_MOCK_PID = $pid;

    eval { $SIG{CHLD} = 'IGNORE' };

    # Wait up to 30s for /__mock__/health.
    my $deadline = time + 30;
    while (time < $deadline) {
        return if _probe_health();
        sleep 0.2;
    }

    $_SKIP_REASON = "mock_relay did not become ready on $HTTP_URL within 30s "
                  . "(clone porting-sdk next to signalwire-perl, or pip install mock_relay)";
    eval { kill 'TERM', $_MOCK_PID } if $_MOCK_PID;
}

sub _probe_health {
    my $resp = _ua()->get("$HTTP_URL/__mock__/health");
    return 0 unless $resp->{success};
    my $payload = eval { decode_json($resp->{content} || '{}') };
    return 0 if $@;
    return exists $payload->{schemas_loaded};
}

END {
    # Preserve the test's exit status; waitpid otherwise stomps $?.
    local $?;
    if ($_MOCK_PID && $_MOCK_PID > 0) {
        eval {
            kill 'TERM', $_MOCK_PID;
            # Wait briefly so the next prove run doesn't race the
            # python uvicorn shutdown when both ports go idle.
            for my $i (1..20) {
                last unless kill 0, $_MOCK_PID;
                Time::HiRes::sleep(0.05);
            }
            # Force-kill if still alive.
            if (kill 0, $_MOCK_PID) {
                kill 'KILL', $_MOCK_PID;
            }
            waitpid($_MOCK_PID, POSIX::WNOHANG);
        };
    }
}

1;

__END__

=head1 NAME

RelayMockTest - test helper for the porting-sdk mock_relay WebSocket server.

=head1 SYNOPSIS

    use lib 't/lib';
    use RelayMockTest;
    use Test::More;

    my $client = RelayMockTest::client(contexts => ["default"]);
    $client->connect_ws;
    $client->authenticate;

    is($client->protocol =~ /^signalwire_/, 1, 'protocol assigned');

    my $j = RelayMockTest::journal_last();
    is($j->{method}, 'signalwire.connect', 'connect frame recorded');

=head1 DESCRIPTION

The mock server's lifetime is per-process: the first RelayMockTest::client()
call probes http://127.0.0.1:9780/__mock__/health and either confirms a
running server or starts one via `python -m mock_relay`. Each test that
calls C<client()> gets a freshly-reset journal and scenarios.

The mock is a real WebSocket server (no monkey-patching). It speaks
ws://, so callers pass C<scheme =E<gt> 'ws'> to the SDK.

=head1 PORTS

WS port 8780 / HTTP port 9780 are reserved for the Perl rollout. Override
with MOCK_RELAY_PORT / MOCK_RELAY_HTTP_PORT env vars.

=cut
