use strict;
use warnings;
use lib 't/lib';
use Test::More;
use TestSSHD;
use Net::LibSSH;
use File::Temp qw(tempdir);

# CWE-322 (CPANSec report, karr #12): ssh_connect() negotiates a host key
# but never checks it against known_hosts -- that is a separate libssh call
# the application has to make, and before this fix connect() never made it.
# SSH_OPTIONS_STRICTHOSTKEYCHECK was accepted by option() and then simply
# never consulted, so with the default settings ANY server, MITM included,
# was accepted silently: the whole point of host key pinning was decoration.
#
# The fix mirrors STRICTHOSTKEYCHECK on the session (libssh has no getter
# for it) and, once ssh_connect() succeeds, calls
# ssh_session_is_known_server() and refuses (spending the session exactly
# like disconnect() does) on anything but SSH_KNOWN_HOSTS_OK -- unless the
# caller explicitly opted out with strict_hostkeycheck => 0, which is
# documented as disabling verification outright and has to keep working
# end-to-end for Rex::LibSSH.
#
# This file proves the refusal is real (a MITM actually gets rejected), that
# opting out actually still lets a real session do real work, and that
# refusing never writes anything back to known_hosts -- these are the three
# ways a "fix" here could look green while being no fix at all.

my $srv = TestSSHD->start;
plan skip_all => 'sshd or ssh-keygen not available' unless $srv;

sub with_timeout {
    my ($seconds, $code) = @_;
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

sub base_ssh {
    my $ssh = Net::LibSSH->new;
    $ssh->option(host => $srv->host);
    $ssh->option(port => $srv->port);
    $ssh->option(user => scalar getpwuid($<));
    return $ssh;
}

# Count the lines in a known_hosts-shaped file. Used to prove a refused
# connect() never appends or rewrites the file it was pointed at -- the
# entire reason knownhosts => '/dev/null' is safe to hand a developer's real
# known_hosts is that this binding only ever reads it.
sub line_count {
    my ($path) = @_;
    open my $fh, '<', $path or return undef;
    my $n = 0;
    $n++ while <$fh>;
    close $fh;
    return $n;
}

# One public key line, read out of an ssh-keygen .pub file.
sub pub_key_line {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    my $line = <$fh>;
    close $fh;
    chomp $line;
    return $line;
}

# A known_hosts file, in the same [host]:port bracketed form TestSSHD uses,
# built from an arbitrary public key -- so tests can hand connect() a
# key that is unknown, changed, or of a different type than the one the
# server actually presents.
sub known_hosts_for {
    my ($pub_path) = @_;
    my $dir  = tempdir(CLEANUP => 1);
    my $path = "$dir/known_hosts";
    open my $fh, '>', $path or die "open $path: $!";
    print $fh '[' . $srv->host . ']:' . $srv->port . ' ' . pub_key_line($pub_path) . "\n";
    close $fh;
    return $path;
}

# A fresh keypair of the given type, in its own tempdir -- ssh-keygen is
# already a hard requirement of TestSSHD, so generating a second (and third)
# keypair here adds no new skip condition.
sub gen_key {
    my ($type) = @_;
    my $dir = tempdir(CLEANUP => 1);
    system('ssh-keygen', '-t', $type, '-N', '', '-f', "$dir/key", '-q') == 0
        or die "ssh-keygen -t $type failed";
    return "$dir/key.pub";
}

my $changed_key_pub = gen_key('ed25519'); # same type as the server's, different key -> CHANGED
my $other_type_pub  = gen_key('ecdsa');   # different type -> OTHER ("type differs")

my $harness_kh_lines_before = line_count($srv->known_hosts);
is $harness_kh_lines_before, 1,
    'sanity: the harness known_hosts starts with exactly the one line it wrote';

# --- 1. trusted key, default (unset) strict_hostkeycheck: the normal path ---
{
    my $ssh = base_ssh();
    $ssh->option(knownhosts => $srv->known_hosts);

    ok with_timeout(10, sub { $ssh->connect }),
        'connect() succeeds against the key the harness known_hosts trusts'
        or diag 'connect: ' . ($ssh->error // '(no error)');
    ok !defined($ssh->error), 'error() is undef after a trusted connect()';

    ok $ssh->auth_publickey($srv->client_key),
        'auth_publickey() succeeds once the host key has been verified'
        or diag 'auth: ' . ($ssh->error // '(no error)');
}

# --- 2. host key not in known_hosts: refused, and the refusal spends the
#        session exactly like disconnect() does -----------------------------
{
    my $ssh = base_ssh();
    $ssh->option(knownhosts => '/dev/null'); # empty file -> SSH_KNOWN_HOSTS_UNKNOWN

    is with_timeout(10, sub { $ssh->connect }), 0,
        'connect() refuses a host key that is not in known_hosts';
    like $ssh->error, qr/not in known_hosts/,
        'error() says the key was not found';

    is with_timeout(10, sub { $ssh->connect }), 0,
        'a second connect() on the same (now spent) object still returns 0';
    like $ssh->error, qr/cannot be reconnected/,
        'and the second error names the session as spent, not the host key '
        . 'again -- the refusal used the same disconnect() plumbing';
}

# --- 3. known_hosts path that does not exist at all: SSH_KNOWN_HOSTS_NOT_FOUND,
#        refused the same way as an empty one ------------------------------
{
    my $missing_dir = tempdir(CLEANUP => 1);
    my $ssh = base_ssh();
    $ssh->option(knownhosts => "$missing_dir/no-such-known-hosts");

    is with_timeout(10, sub { $ssh->connect }), 0,
        'connect() refuses when the known_hosts file does not exist';
    like $ssh->error, qr/not in known_hosts/,
        'error() gives the same "not in known_hosts" message as the empty-file case';
}

# --- 4. same key type, different key content: SSH_KNOWN_HOSTS_CHANGED, the
#        actual MITM shape -- must name the possibility explicitly ---------
{
    my $kh = known_hosts_for($changed_key_pub);
    my $before = line_count($kh);

    my $ssh = base_ssh();
    $ssh->option(knownhosts => $kh);

    is with_timeout(10, sub { $ssh->connect }), 0,
        'connect() refuses a host key that has changed from the known_hosts entry';
    like $ssh->error, qr/has changed/, 'error() says the key has changed';
    like $ssh->error, qr/man-in-the-middle/i, 'and names the man-in-the-middle possibility';

    is line_count($kh), $before,
        'the changed-key known_hosts file was not rewritten by the refusal';
}

# --- 5. same host:port, but the only known_hosts entry is a different key
#        type: SSH_KNOWN_HOSTS_OTHER --------------------------------------
{
    my $kh = known_hosts_for($other_type_pub);
    my $before = line_count($kh);

    my $ssh = base_ssh();
    $ssh->option(knownhosts => $kh);

    is with_timeout(10, sub { $ssh->connect }), 0,
        'connect() refuses when known_hosts only has an entry of a different key type';
    like $ssh->error, qr/type differs/, 'error() says the key type differs';

    is line_count($kh), $before,
        'the different-type known_hosts file was not rewritten by the refusal';
}

# --- 6. strict_hostkeycheck => 0: the documented opt-out, exercised end to
#        end -- this is the Rex::LibSSH path and it has to still do real work
{
    my $ssh = base_ssh();
    $ssh->option(knownhosts => '/dev/null');
    $ssh->option(strict_hostkeycheck => 0);

    ok with_timeout(10, sub { $ssh->connect }),
        'connect() succeeds with strict_hostkeycheck => 0 and an unknown key'
        or diag 'connect: ' . ($ssh->error // '(no error)');
    ok $ssh->auth_publickey($srv->client_key), 'auth_publickey() still succeeds';

    my $ch = $ssh->channel;
    ok defined $ch, 'channel() returns an object';
    ok with_timeout(10, sub { $ch->exec('echo ok') }), 'exec() succeeds';
    my $out = with_timeout(10, sub { $ch->read });
    chomp $out;
    is $out, 'ok', 'the exec-channel round trip works with verification disabled';
    $ch->close;
}

# --- 7. strict_hostkeycheck => 0 also accepts a key that plainly changed --
#        "disabled" is documented to mean disabled, not "still catch a MITM" ---
{
    my $ssh = base_ssh();
    $ssh->option(knownhosts => known_hosts_for($changed_key_pub));
    $ssh->option(strict_hostkeycheck => 0);

    ok with_timeout(10, sub { $ssh->connect }),
        'connect() succeeds with strict_hostkeycheck => 0 even against a changed key'
        or diag 'connect: ' . ($ssh->error // '(no error)');
}

# --- 8. strict_hostkeycheck follows the LAST option() call on the object --
{
    my $ssh = base_ssh();
    $ssh->option(knownhosts => '/dev/null');
    $ssh->option(strict_hostkeycheck => 0);
    $ssh->option(strict_hostkeycheck => 1); # re-enables it

    is with_timeout(10, sub { $ssh->connect }), 0,
        'strict_hostkeycheck => 1 after => 0 re-enables verification';
    like $ssh->error, qr/not in known_hosts/,
        'and the refusal is the normal unknown-key one, proving the check ran';
}

# --- 9. nothing here ever wrote back into the harness known_hosts ---------
is line_count($srv->known_hosts), $harness_kh_lines_before,
    'the harness known_hosts still has exactly the line it started with';

done_testing;
