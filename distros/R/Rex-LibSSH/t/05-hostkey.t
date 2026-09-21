use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Temp qw(tempdir);
use TestSSHD;

# CWE-322 (CPANSec report, karr k8): Rex::Interface::Connection::LibSSH::connect
# hardcodes strict_hostkeycheck => 0 and never looks at $opt{strict_hostkeycheck}
# or $opt{knownhosts} -- so the opt-in documented in lib/Rex/LibSSH.pm POD
# ("To enable it, pass the option when connecting") is a no-op: every host key,
# MITM included, is accepted silently regardless of what a caller asks for.
#
# This file proves: the strict default actually refuses an unverified key (and
# never authenticates against it), that an explicit knownhosts file is what
# makes a real connect succeed, that a changed key is refused as a possible
# MITM without rewriting the known_hosts file, that the documented
# strict_hostkeycheck => 0 opt-out still does real work end-to-end (the
# Rex::GPU / Rex::Rancher path on fresh Hetzner installs), that the
# openssh_opt-based knobs Rex tasks use instead of calling Rex::connect
# directly are consulted, and that a per-connect option wins over them.

my $srv = TestSSHD->start;
plan skip_all => 'sshd or ssh-keygen not available' unless $srv;

# Net::LibSSH >= 0.004 is where connect() started calling
# ssh_session_is_known_server() at all -- on an older version every
# assertion below about refusal is unreachable, not skippable. Fail loud.
use Net::LibSSH;
if ( $Net::LibSSH::VERSION < 0.004 ) {
    die "t/05-hostkey.t requires Net::LibSSH >= 0.004 for host key "
      . "verification (ssh_session_is_known_server); found "
      . "$Net::LibSSH::VERSION -- karr k8 cannot be exercised on this version.\n";
}

use Rex -feature => ['1.4'];
use Rex::Group::Entry::Server;
use Rex::Commands::Run;
use Rex::Config;
use Rex::Interface::Connection;
use Rex::TaskList;

set connection => 'LibSSH';

Rex::Config->set_user( scalar getpwuid($<) );
Rex::Config->set_private_key( $srv->client_key );
Rex::Config->set_public_key( $srv->client_key . '.pub' );

sub with_timeout {
    my ( $seconds, $code ) = @_;
    my $result;
    local $@;
    eval {
        local $SIG{ALRM} = sub { die "TIMEOUT\n" };
        alarm($seconds);
        $result = $code->();
        alarm(0);
    };
    my $err = $@;
    alarm(0);
    die $err if $err;
    return $result;
}

# Count the lines in a known_hosts-shaped file. Used to prove a refused
# connect never appends or rewrites the file it was pointed at.
sub line_count {
    my ($path) = @_;
    CORE::open my $fh, '<', $path or return undef;
    my $n = 0;
    $n++ while <$fh>;
    CORE::close $fh;
    return $n;
}

sub pub_key_line {
    my ($path) = @_;
    CORE::open my $fh, '<', $path or die "open $path: $!";
    my $line = <$fh>;
    CORE::close $fh;
    chomp $line;
    return $line;
}

# A known_hosts file, in the same [host]:port bracketed form TestSSHD uses,
# built from an arbitrary public key -- so a test can hand connect() a key
# that is unknown or has changed from the one the server actually presents.
sub known_hosts_for {
    my ($pub_path) = @_;
    my $dir  = tempdir( CLEANUP => 1 );
    my $path = "$dir/known_hosts";
    CORE::open my $fh, '>', $path or die "open $path: $!";
    print $fh '[' . $srv->host . ']:' . $srv->port . ' ' . pub_key_line($pub_path) . "\n";
    CORE::close $fh;
    return $path;
}

# A fresh ed25519 keypair in its own tempdir -- ssh-keygen is already a hard
# requirement of TestSSHD, so generating a second one here adds no new skip
# condition.
sub gen_key {
    my $dir = tempdir( CLEANUP => 1 );
    system( 'ssh-keygen', '-t', 'ed25519', '-N', '', '-f', "$dir/key", '-q' ) == 0
        or die "ssh-keygen failed";
    return "$dir/key.pub";
}

sub base_opts {
    return (
        server      => $srv->host,
        port        => $srv->port,
        user        => scalar getpwuid($<),
        private_key => $srv->client_key,
        public_key  => $srv->client_key . '.pub',
        auth_type   => 'key',
    );
}

# Rex::connect dies before push_connection when is_connected is false, so
# there is nothing to pop in the normal "refused" case below. This is a
# defensive net around that, not the expected path: pop only if a
# connection was actually pushed, i.e. either Rex::connect unexpectedly
# succeeded (which would mean a refusal test regressed) or it died after
# already pushing (the "Wrong username" auth-failure path, which pushes
# before its own die). Keeps every refusal block safe to run unattended
# regardless of which of those it hits.
sub pop_if_pushed {
    my ($err) = @_;
    Rex::pop_connection() if !$err || $err =~ /Wrong username/;
}

my $harness_kh_lines_before = line_count( $srv->known_hosts );
is $harness_kh_lines_before, 1,
    'sanity: the harness known_hosts starts with exactly the one line it wrote';

# --- 1. Default is strict: no knownhosts/strict_hostkeycheck option
#        anywhere -- Rex::connect must refuse an unverified host key --------
{
    eval { Rex::connect( base_opts() ) };
    my $err = $@;
    pop_if_pushed($err);
    like $err, qr/Connection error or refused\./,
        'Rex::connect dies against an unknown host key with no options given (default strict)';
}

# Same scenario, driving the connection interface object directly -- when
# Rex::connect dies, its own $conn is a lexical that is lost, so this is the
# only way to inspect is_connected / is_authenticated / error after a
# refusal.
{
    my $conn = Rex::Interface::Connection->create('LibSSH');
    with_timeout( 10, sub { $conn->connect( base_opts() ) } );

    is $conn->is_connected, 0,
        'connection object: is_connected is 0 after a default-strict refusal';
    is $conn->is_authenticated, 0,
        'connection object: is_authenticated is 0 -- authentication must not have happened';
    like $conn->error // '', qr/not in known_hosts/,
        q{connection object: error() carries libssh's refusal message};
}

# --- 2. knownhosts => file naming exactly this server -- connect + auth
#        succeed, and a real command actually runs ---------------------------
{
    Rex::connect( base_opts(), knownhosts => $srv->known_hosts );

    my $conn = Rex::get_current_connection()->{conn};
    ok $conn->is_connected,     'knownhosts => harness file: is_connected true';
    ok $conn->is_authenticated, 'knownhosts => harness file: is_authenticated true';

    my $out = run 'echo hello';
    chomp $out;
    is $out, 'hello', 'knownhosts => harness file: run works after connect';

    Rex::pop_connection();
}

# --- 3. known_hosts entry present but for a DIFFERENT key -- the actual MITM
#        shape: refused, and the crafted file must not be rewritten ---------
{
    my $changed_key_pub = gen_key();
    my $kh              = known_hosts_for($changed_key_pub);
    my $before           = line_count($kh);

    eval { Rex::connect( base_opts(), knownhosts => $kh ) };
    my $err = $@;
    pop_if_pushed($err);
    like $err, qr/Connection error or refused\./,
        'Rex::connect dies against a known_hosts entry carrying a different (changed) key';

    my $conn = Rex::Interface::Connection->create('LibSSH');
    with_timeout( 10, sub { $conn->connect( base_opts(), knownhosts => $kh ) } );
    like $conn->error // '', qr/man-in-the-middle/i,
        'connection object: error() names the man-in-the-middle possibility for a changed key';

    is line_count($kh), $before,
        'the crafted known_hosts file was not rewritten by the refusal';
}

# --- 4. strict_hostkeycheck => 0 with knownhosts => /dev/null -- the
#        documented opt-out, exercised end to end (Rex::GPU / Rex::Rancher
#        on a fresh Hetzner install with no known_hosts entry at all) -------
{
    Rex::connect(
        base_opts(),
        knownhosts          => '/dev/null',
        strict_hostkeycheck => 0,
    );

    my $conn = Rex::get_current_connection()->{conn};
    ok $conn->is_connected,     'strict_hostkeycheck => 0: is_connected true with an unknown key';
    ok $conn->is_authenticated, 'strict_hostkeycheck => 0: is_authenticated true';

    my $out = run 'echo hello';
    chomp $out;
    is $out, 'hello', 'strict_hostkeycheck => 0: run works';

    Rex::pop_connection();
}

# --- 5a. Rex-native knob for task context: Rex::Config->set_openssh_opt(
#         StrictHostKeyChecking => 'no' ) -- exactly what
#         use Rex -feature => ['disable_strict_host_key_checking'] does
#         (Rex.pm ~line 849) -- with no per-connect strict option and
#         knownhosts => '/dev/null' -- connects. Resetting the key (setting
#         it to undef deletes it, per Rex::Config::set_openssh_opt POD)
#         restores the strict default. ------------------------------------
{
    Rex::Config->set_openssh_opt( StrictHostKeyChecking => 'no' );

    Rex::connect( base_opts(), knownhosts => '/dev/null' );

    my $conn = Rex::get_current_connection()->{conn};
    ok $conn->is_connected,
        'openssh_opt StrictHostKeyChecking => no: is_connected true with an unknown key';
    ok $conn->is_authenticated,
        'openssh_opt StrictHostKeyChecking => no: is_authenticated true';

    Rex::pop_connection();

    Rex::Config->set_openssh_opt( StrictHostKeyChecking => undef );

    eval { Rex::connect( base_opts(), knownhosts => '/dev/null' ) };
    my $err = $@;
    pop_if_pushed($err);
    like $err, qr/Connection error or refused\./,
        'resetting StrictHostKeyChecking (undef deletes the key) restores the strict default';
}

# --- 5b. Rex::Config->set_openssh_opt( UserKnownHostsFile => ... ) with
#         strict default (no per-connect knownhosts at all) -- connects ----
{
    Rex::Config->set_openssh_opt( UserKnownHostsFile => $srv->known_hosts );

    Rex::connect( base_opts() );

    my $conn = Rex::get_current_connection()->{conn};
    ok $conn->is_connected,
        'openssh_opt UserKnownHostsFile: is_connected true against the trusted key, strict default';
    ok $conn->is_authenticated,
        'openssh_opt UserKnownHostsFile: is_authenticated true';

    my $out = run 'echo hello';
    chomp $out;
    is $out, 'hello', 'openssh_opt UserKnownHostsFile: run works';

    Rex::pop_connection();

    Rex::Config->set_openssh_opt( UserKnownHostsFile => undef );
}

# --- 5c. a per-connect option wins over the openssh_opt fallback ----------
{
    # openssh_opt says "don't check"; the per-connect option says "check,
    # strictly, against a file where this key is unknown" -- per-connect
    # must win, so this must still be refused.
    Rex::Config->set_openssh_opt( StrictHostKeyChecking => 'no' );

    eval {
        Rex::connect(
            base_opts(),
            knownhosts          => '/dev/null',
            strict_hostkeycheck => 1,
        );
    };
    my $err = $@;
    pop_if_pushed($err);
    like $err, qr/Connection error or refused\./,
        'a per-connect strict_hostkeycheck => 1 overrides an openssh_opt StrictHostKeyChecking => no';

    Rex::Config->set_openssh_opt( StrictHostKeyChecking => undef );
}

# --- 6. the real task path: Rex::connect is never called, only
#        Rex::Task->run($server) -- proves the openssh_opt fallback is read
#        by the connection class itself, not bolted onto the Rex::connect
#        wrapper alone. --------------------------------------------------
{
    Rex::Config->set_openssh_opt( StrictHostKeyChecking => 'no' );

    my $task_output;
    task 'hostkey_task_path_test', sub {
        $task_output = run 'echo task-path-ok';
    };

    my $server = Rex::Group::Entry::Server->new(
        name        => $srv->host,
        port        => $srv->port,
        user        => scalar getpwuid($<),
        private_key => $srv->client_key,
        public_key  => $srv->client_key . '.pub',
        auth_type   => 'key',
    );

    my $task = Rex::TaskList->create()->get_task('hostkey_task_path_test');
    eval { $task->run($server) };
    my $err = $@;
    ok !$err,
        'task path: Rex::Task->run() against an unknown host key succeeds via the openssh_opt opt-out'
        or diag "task run died: $err";

    if ( !$err ) {
        my $got = $task_output // '';
        chomp $got;
        is $got, 'task-path-ok',
            'task path: the task body actually executed on the remote host';
    }
    else {
        fail 'task path: the task body actually executed on the remote host (task run died)';
    }

    Rex::Config->set_openssh_opt( StrictHostKeyChecking => undef );
}

# --- 7. nothing above ever wrote back into the harness known_hosts --------
is line_count( $srv->known_hosts ), $harness_kh_lines_before,
    'the harness known_hosts still has exactly the line it started with';

done_testing;
