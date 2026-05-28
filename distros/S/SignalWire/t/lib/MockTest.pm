package MockTest;

# Test helper for the porting-sdk mock_signalwire HTTP server.
#
# Mirrors the Python conftest fixtures and the Go pilot's mocktest package:
# - On first call to MockTest::client(), probe http://127.0.0.1:8770/__mock__/health
#   and either reuse a running mock server or spawn one as a subprocess.
# - Each test calls MockTest::journal_reset() before exercising the SDK so it
#   only sees its own request, then MockTest::journal_last() to inspect what
#   the SDK actually sent over the wire.
# - PORT 8770 is reserved for the Perl rollout (see porting-sdk/test_harness/
#   mock_signalwire/README.md).

use strict;
use warnings;

use HTTP::Tiny;
use JSON qw(encode_json decode_json);
use POSIX ();
use Time::HiRes qw(sleep);
use IPC::Open3 ();
use Symbol ();
use IO::Handle ();
use File::Spec ();
use Cwd ();
use Config ();

use SignalWire::REST::RestClient;

our $VERSION = '0.01';

our $PORT = $ENV{MOCK_SIGNALWIRE_PORT} || 8770;
our $HOST = '127.0.0.1';
our $BASE_URL = "http://$HOST:$PORT";

our $PROJECT = 'test_proj';
our $TOKEN   = 'test_tok';

# Singleton state. The mock server's lifetime is per-process: the first
# client() call probes for a running instance, then either reuses it or
# spawns one as a subprocess.
our $_UA;
our $_MOCK_PID;
our $_ENSURED = 0;
our $_SKIP_REASON;

# Public API ---------------------------------------------------------------

# client() returns a SignalWire::REST::RestClient pointed at the mock.
# Resets the journal so every test starts clean.
sub client {
    _ensure_server();
    if ($_SKIP_REASON) {
        Test::More::plan(skip_all => "MockTest: $_SKIP_REASON");
        exit 0;
    }
    journal_reset();
    scenario_reset();
    return SignalWire::REST::RestClient->new(
        project => $PROJECT,
        token   => $TOKEN,
        host    => $BASE_URL,
    );
}

# journal_reset clears all request entries on the mock.
sub journal_reset {
    _ensure_server();
    return if $_SKIP_REASON;
    my $resp = _ua()->post("$BASE_URL/__mock__/journal/reset");
    die "journal_reset failed: $resp->{status}" unless $resp->{success};
}

# scenario_reset clears any one-shot scenarios.
sub scenario_reset {
    _ensure_server();
    return if $_SKIP_REASON;
    my $resp = _ua()->post("$BASE_URL/__mock__/scenarios/reset");
    die "scenario_reset failed: $resp->{status}" unless $resp->{success};
}

# scenario_set stages a one-shot response override for the named OperationId.
# scenario_set("calling.call-commands", 500, { error => "boom" })
sub scenario_set {
    my ($endpoint_id, $status, $response_body) = @_;
    _ensure_server();
    return if $_SKIP_REASON;
    my $payload = encode_json({ status => $status, response => $response_body });
    my $resp = _ua()->post(
        "$BASE_URL/__mock__/scenarios/$endpoint_id",
        { content => $payload, headers => { 'Content-Type' => 'application/json' } },
    );
    die "scenario_set failed: $resp->{status} - $resp->{content}" unless $resp->{success};
}

# journal_all returns the array-of-hashref of every recorded request since
# the last reset, in arrival order.
sub journal_all {
    _ensure_server();
    die "MockTest: $_SKIP_REASON" if $_SKIP_REASON;
    my $resp = _ua()->get("$BASE_URL/__mock__/journal");
    die "journal fetch failed: $resp->{status}" unless $resp->{success};
    return decode_json($resp->{content} || '[]');
}

# journal_last returns the most recently recorded request. Dies if the
# journal is empty - every test that calls a mock-backed SDK method should
# produce at least one entry.
sub journal_last {
    my @entries = @{ journal_all() };
    die "MockTest: journal is empty - SDK call did not reach mock server"
        unless @entries;
    return $entries[-1];
}

# Internals ----------------------------------------------------------------

sub _ua {
    return $_UA ||= HTTP::Tiny->new( timeout => 5 );
}

# Walk this file's directory upward looking for an adjacent
# ../porting-sdk/test_harness/<name>/<name>/__init__.py.
#
# Returns the absolute path to the directory containing the Python package
# (the value to put on PYTHONPATH so that `python -m <name>` resolves), or
# undef when no adjacent porting-sdk is reachable.
sub discover_porting_sdk_package {
    my ($name) = @_;
    my $here = Cwd::abs_path(__FILE__);
    return undef unless defined $here;
    my $dir = File::Spec->canonpath((File::Spec->splitpath($here))[1]);
    # File::Spec->splitpath returns trailing slash on the directory, strip.
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
        # Reuse whatever's already listening (we did not spawn it).
        return;
    }

    # Try to inject porting-sdk/test_harness/mock_signalwire/ into
    # PYTHONPATH so `python -m mock_signalwire` resolves without a prior
    # `pip install -e ...`. Adjacency contract: porting-sdk next to
    # signalwire-perl in ~/src/. When the walk fails we still spawn — the
    # child falls back to whatever is on the system Python's sys.path,
    # and the readiness probe surfaces a clear timeout error if neither
    # mode is available.
    my $pkg_dir = discover_porting_sdk_package('mock_signalwire');
    my $sep = $Config::Config{path_sep} // ':';
    my $existing = defined $ENV{PYTHONPATH} ? $ENV{PYTHONPATH} : '';
    local $ENV{PYTHONPATH} = defined $pkg_dir
        ? ($existing ne '' ? "$pkg_dir$sep$existing" : $pkg_dir)
        : $existing;

    # Try to spawn `python -m mock_signalwire`. On any failure, set the
    # skip reason and leave it to client() to plan(skip_all).
    my @cmd = (
        'python', '-m', 'mock_signalwire',
        '--host', $HOST,
        '--port', $PORT,
        '--log-level', 'error',
    );

    my ($wtr, $rdr, $err);
    $err = Symbol::gensym();
    my $pid = eval {
        IPC::Open3::open3($wtr, $rdr, $err, @cmd);
    };
    if ($@ || !$pid) {
        $_SKIP_REASON = "could not spawn `@cmd`: $@";
        return;
    }
    $_MOCK_PID = $pid;
    # Detach by closing pipes; we only care that the process is alive.
    close $wtr if $wtr;
    close $rdr if $rdr;
    close $err if $err;

    # Reap on END to avoid zombies.
    eval {
        $SIG{CHLD} = 'IGNORE';
    };

    # Wait up to 30s for /__mock__/health.
    my $deadline = time + 30;
    while (time < $deadline) {
        if (_probe_health()) {
            return;
        }
        sleep 0.2;
    }

    $_SKIP_REASON = "mock_signalwire did not become ready on $BASE_URL within 30s "
                  . "(clone porting-sdk next to signalwire-perl so tests can find "
                  . "porting-sdk/test_harness/mock_signalwire/, or pip install the mock_signalwire package)";
    eval { kill 'TERM', $_MOCK_PID } if $_MOCK_PID;
}

sub _probe_health {
    my $resp = _ua()->get("$BASE_URL/__mock__/health");
    return 0 unless $resp->{success};
    my $payload = eval { decode_json($resp->{content} || '{}') };
    return 0 if $@;
    return exists $payload->{specs_loaded};
}

END {
    if ($_MOCK_PID && $_MOCK_PID > 0) {
        # Politely terminate; the OS will clean up either way.
        eval { kill 'TERM', $_MOCK_PID };
    }
}

1;

__END__

=head1 NAME

MockTest - test helper for the porting-sdk mock_signalwire HTTP server.

=head1 SYNOPSIS

    use lib 't/lib';
    use MockTest;
    use Test::More;

    my $client = MockTest::client();
    my $body = $client->compat->calls->start_stream(
        'CA_TEST', Url => 'wss://example.com/stream', Name => 'my-stream',
    );
    is(ref $body, 'HASH', 'response is a hashref');

    my $j = MockTest::journal_last();
    is($j->{method}, 'POST', 'POST recorded');
    is($j->{path},
       '/api/laml/2010-04-01/Accounts/test_proj/Calls/CA_TEST/Streams',
       'path matches');
    is($j->{body}{Url}, 'wss://example.com/stream', 'body Url forwarded');

=head1 DESCRIPTION

The mock server's lifetime is per-process: the first MockTest::client()
call probes http://127.0.0.1:8770/__mock__/health and either confirms
a running server or starts one via `python -m mock_signalwire`. Each
test that calls C<client()> gets a freshly-reset journal so subsequent
journal_last() calls return only that test's request.

=head1 PORT

Port 8770 is reserved for the Perl rollout. Override with the
MOCK_SIGNALWIRE_PORT environment variable.

=cut
