use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Temp qw(tempdir);
use TestSSHD;

# These tests guard the security-relevant line in this distribution:
# every path goes through _q() except Fs::LibSSH::glob, whose pattern
# must stay unquoted so the remote shell expands *, ?, [...]. The
# asymmetry is documented in lib/Rex/Interface/Fs/LibSSH.pm next to
# glob(); the unit tests below lock down the quoting contract.

use Rex::Interface::Fs::LibSSH;
use Rex::Interface::File::LibSSH;

# ============================================================
# Unit tests -- _q() and glob hardening (no sshd required)
# ============================================================

subtest 'Fs::_q round-trips through single-quote shell semantics' => sub {
    plan tests => 9;

    # Each input below, after _q() and shell un-quoting, MUST produce
    # exactly the original byte sequence. _q() handles these for free
    # because inside '...' the shell performs no expansion.
    is( Rex::Interface::Fs::LibSSH::_q("foo"),          "'foo'",            'plain ascii' );
    is( Rex::Interface::Fs::LibSSH::_q(""),            "''",               'empty string' );
    is( Rex::Interface::Fs::LibSSH::_q("foo bar"),     "'foo bar'",        'space' );
    is( Rex::Interface::Fs::LibSSH::_q("o'clock"),     q['o'"'"'clock'],   'embedded single quote' );
    is( Rex::Interface::Fs::LibSSH::_q('a$b'),         "'a\$b'",           'dollar (literal in single quotes)' );
    is( Rex::Interface::Fs::LibSSH::_q('`cmd`'),       "'`cmd`'",          'backticks (literal in single quotes)' );
    is( Rex::Interface::Fs::LibSSH::_q("back\\slash"), "'back\\slash'",    'backslash (literal in single quotes)' );
    is( Rex::Interface::Fs::LibSSH::_q("line1\nline2"),"'line1\nline2'",   'newline (literal in single quotes)' );

    # NUL cannot be represented in argv; libssh would silently truncate.
    eval { Rex::Interface::Fs::LibSSH::_q("foo\0bar") };
    like( $@, qr/NUL/, '_q dies on NUL byte' );
};

subtest 'File::_q matches Fs::_q contract' => sub {
    plan tests => 3;

    is( Rex::Interface::File::LibSSH::_q("o'clock"), q['o'"'"'clock'],
        'File _q: single quote' );
    is( Rex::Interface::File::LibSSH::_q('a$b'), "'a\$b'",
        'File _q: dollar literal' );
    eval { Rex::Interface::File::LibSSH::_q("foo\0bar") };
    like( $@, qr/NUL/, 'File _q dies on NUL byte' );
};

subtest 'glob rejects shell metacharacters beyond glob syntax' => sub {
    plan tests => 8;

    # Every entry below contains a character that would let the pattern
    # break out of "echo <pattern>" and execute an arbitrary command.
    # The hardened glob must die before _run() opens an ssh channel.
    for my $case (
        [ "/*; touch /tmp/rex-libssh-whatever", 'semicolon' ],
        [ "foo|bar",                           'pipe' ],
        [ "foo&bar",                           'ampersand' ],
        [ "foo>bar",                           'redirect out' ],
        [ "foo<bar",                           'redirect in' ],
        [ 'foo`bar`',                          'backtick' ],
        [ 'foo$(bar)',                         'dollar-paren' ],
        [ "foo;rm -rf /",                      'injection rm -rf' ],
    ) {
        my ( $pat, $label ) = @$case;
        eval { Rex::Interface::Fs::LibSSH->new->glob($pat) };
        like( $@, qr/(NUL|metachar)/,
            "glob rejects $label pattern: $pat" );
    }
};

# ============================================================
# Integration tests -- drive a real sshd
# ============================================================

my $srv = TestSSHD->start;
unless ($srv) {
    plan skip_all => 'sshd or ssh-keygen not available';
}

use Rex -feature => ['1.4'];
use Rex::Group::Entry::Server;
use Rex::Commands::Fs;
use Rex::Commands::File;
use Rex::Config;

set connection => 'LibSSH';

Rex::Config->set_user( scalar getpwuid($<) );
Rex::Config->set_private_key( $srv->client_key );
Rex::Config->set_public_key( $srv->client_key . '.pub' );

Rex::connect(
    server      => $srv->host,
    port        => $srv->port,
    user        => scalar( getpwuid($<) ),
    private_key => $srv->client_key,
    public_key  => $srv->client_key . '.pub',
    auth_type   => 'key',
    knownhosts  => $srv->known_hosts,
);

# Use a fresh tempdir on the remote side (the sshd is local, so a
# local /tmp path is visible to the remote user too).
my $dir = tempdir(CLEANUP => 1);

# Local source file for upload(). All "remote file creation" goes
# through upload (cat > $qpath) so the test is independent of
# Rex::Commands::File, which post-verifies with md5sum and uses a
# single-quoted path without escaping -- an upstream bug for paths
# containing '. Our _q() handles ' correctly; the test exercises
# the Fs::LibSSH layer that we control.
my $src = "$dir/local-src-$$";
open( my $sfh, '>', $src ) or die "cannot write $src: $!";
print $sfh "x\n";
close $sfh;

subtest 'is_file + stat + unlink with paths containing shell metacharacters' => sub {
    plan tests => 12;

    # Each block: create a file with an odd name (upload -> Fs::LibSSH
    # which goes through _q), verify is_file and stat, then unlink it.

    # --- space ---
    my $space = "$dir/has space.txt";
    upload $src, $space;
    ok  is_file($space),          'is_file: path with space';
    my %st = stat($space);
    ok  $st{size} > 0,            'stat: path with space returns size';
    ok  defined $st{mode},        'stat: path with space returns mode';
    unlink $space;
    ok !is_file($space),          'unlink: path with space removed';

    # --- single quote ---
    my $q = "$dir/o'clock.txt";
    upload $src, $q;
    ok  is_file($q),              'is_file: path with single quote';
    unlink $q;
    ok !is_file($q),              'unlink: path with single quote';

    # --- $ ---
    my $d = "$dir/price\$100.txt";
    upload $src, $d;
    ok  is_file($d),              'is_file: path with dollar';
    unlink $d;
    ok !is_file($d),              'unlink: path with dollar';

    # --- backtick ---
    my $b = "$dir/`echo injected`.txt";
    upload $src, $b;
    ok  is_file($b),              'is_file: path with backticks';
    unlink $b;
    ok !is_file($b),              'unlink: path with backticks';

    # --- newline ---
    my $n = "$dir/line1\nline2.txt";
    upload $src, $n;
    ok  is_file($n),              'is_file: path with newline';
    unlink $n;
    ok !is_file($n),              'unlink: path with newline';
};

subtest 'upload + download with paths containing shell metacharacters' => sub {
    plan tests => 6;

    # --- single quote in remote path ---
    my $src = "$dir/src-upload-$$";
    open( my $fh, '>', $src ) or die "cannot write $src: $!";
    print $fh "uploaded via odd path\n";
    close $fh;

    my $remote_q = "$dir/'odd quote'.txt";
    upload $src, $remote_q;
    ok is_file($remote_q), 'upload: remote path with single quote';

    my $dst_q = "$dir/downloaded-$$";
    download $remote_q, $dst_q;
    open( my $dfh, '<', $dst_q ) or die $!;
    my $got = <$dfh>;
    close $dfh;
    is $got, "uploaded via odd path\n",
        'download: content preserved through single-quote path';

    unlink $remote_q;
    ok !is_file($remote_q), 'cleanup: odd-quote path unlinked';

    # --- space in remote path ---
    my $remote_s = "$dir/odd space.txt";
    upload $src, $remote_s;
    ok is_file($remote_s), 'upload: remote path with space';

    my $dst_s = "$dir/downloaded-s-$$";
    download $remote_s, $dst_s;
    open( my $sfh, '<', $dst_s ) or die $!;
    my $gs = <$sfh>;
    close $sfh;
    is $gs, "uploaded via odd path\n",
        'download: content preserved through space path';

    unlink $remote_s;
    ok !is_file($remote_s), 'cleanup: space path unlinked';
};

subtest 'legitimate glob still works after hardening' => sub {
    plan tests => 2;

    # Make sure the regex blacklist didn't accidentally reject real
    # glob meta-chars (*, ?, [...]) or ordinary path bytes.
    my @hosts = Rex::Interface::Fs::LibSSH->new->glob('/etc/hos*');
    ok scalar(@hosts) >= 1, 'glob /etc/hos* returns matches (legitimate *)';

    # An unmatched glob is passed through literally by the default
    # shell (no nullglob/failglob set), so echo emits the pattern
    # itself -- one element, the literal pattern. This documents the
    # observable behaviour rather than asserting empty.
    my @none = Rex::Interface::Fs::LibSSH->new->glob('/etc/nonexistent.glob.*.xyz');
    is scalar(@none), 1, 'glob with no matches echoes the literal pattern';
};

subtest 'hostile glob pattern does not execute anything beyond globbing' => sub {
    plan tests => 2;

    # If glob's hardening is bypassed, this pattern would emit
    #     echo /*; touch <marker>; echo done
    # over ssh and the marker file would appear. We verify it does NOT.
    my $marker = "/tmp/rex-libssh-glob-marker-$$";
    unlink $marker;

    eval {
        Rex::Interface::Fs::LibSSH->new->glob(
            "/*; touch $marker; echo pwned" );
    };
    ok $@, 'glob dies on injection pattern (semicolon)';

    ok !-e $marker,
        'glob did not create the marker file via injection';
};

Rex::pop_connection();

done_testing;
