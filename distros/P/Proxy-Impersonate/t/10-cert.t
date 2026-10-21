use v5.10; use strict; use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Net::SSLeay ();
use Proxy::Impersonate::Cert;

my $dir = tempdir(CLEANUP => 1);
my $c = Proxy::Impersonate::Cert->new(cert_dir => $dir);
ok(-r $c->cert_path && -r $c->key_path, 'cert+key persisted to disk');
ok($c->cert, 'cert object available');
ok($c->key,  'key object available');

# self-signed: issuer == subject
is(Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_issuer_name($c->cert)),
   Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_subject_name($c->cert)),
   'cert is self-signed (issuer == subject)');

# stable across instances (persisted, not regenerated)
my $pem1 = do { open my $f, '<', $c->cert_path; local $/; <$f> };
my $c2   = Proxy::Impersonate::Cert->new(cert_dir => $dir);
my $pem2 = do { open my $f, '<', $c2->cert_path; local $/; <$f> };
is($pem1, $pem2, 'cert is stable across instances (persisted)');

# key file is private
my $mode = (stat $c->key_path)[2] & 07777;
is($mode & 077, 0, 'key file is not group/other readable');

# applies to a server CTX without error
my $ctx = Net::SSLeay::CTX_new();
ok(eval { $c->apply_to_ctx($ctx); 1 }, 'apply_to_ctx succeeds') or diag($@);
Net::SSLeay::CTX_free($ctx);

# --- refuse to ADOPT an unsafe pre-existing key ---------------------------
#
# cert_dir defaults to a 0700 File::Temp dir, but the option exists so a caller
# can persist the cert somewhere of their own choosing -- and a shared location
# is where this goes wrong. Whoever can write that key can impersonate this
# proxy to the browser it fronts, which is configured to accept its
# certificate. These pin the refusals rather than trusting the comment.
{
    my $d2 = tempdir(CLEANUP => 1);
    my $c3 = Proxy::Impersonate::Cert->new(cert_dir => $d2);   # generated normally
    ok(-r $c3->key_path, 'generated a key in a fresh dir');

    chmod 0644, $c3->key_path;
    my $err = '';
    eval { Proxy::Impersonate::Cert->new(cert_dir => $d2); 1 } or $err = $@;
    like($err, qr/accessible beyond its owner/, 'refuses a group/world-readable key');

    chmod 0600, $c3->key_path;
    ok(eval { Proxy::Impersonate::Cert->new(cert_dir => $d2); 1 },
       'a 0600 key is adopted normally') or diag($@);

    # judged on the LINK, not its target: a symlink pointing at a 0600 file
    # would otherwise pass a naive stat()
    my $real = $c3->key_path . '.real';
    rename $c3->key_path, $real or die "rename: $!";
    symlink $real, $c3->key_path or die "symlink: $!";
    $err = '';
    eval { Proxy::Impersonate::Cert->new(cert_dir => $d2); 1 } or $err = $@;
    like($err, qr/is a symlink/, 'refuses a symlinked key');
}

{
    my $bad = tempdir(CLEANUP => 1);
    open my $f, '>', "$bad/cert.pem" or die $!;
    print $f 'broken'; close $f;
    eval { Proxy::Impersonate::Cert->new(cert_dir => $bad) };
    like($@, qr/incomplete/, 'partial pair fails at startup');
    open $f, '>', "$bad/key.pem" or die $!;
    print $f 'broken'; close $f; chmod 0600, "$bad/key.pem";
    eval { Proxy::Impersonate::Cert->new(cert_dir => $bad) };
    like($@, qr/invalid certificate/, 'corrupt PEM fails at startup');
}

{
    my $other = Proxy::Impersonate::Cert->new(cert_dir => tempdir(CLEANUP => 1));
    my $pem = Net::SSLeay::PEM_get_string_PrivateKey($other->key);
    open my $f, '>', $c->key_path or die $!;
    print $f $pem; close $f;
    eval { Proxy::Impersonate::Cert->new(cert_dir => $dir) };
    like($@, qr/mismatched/, 'mismatched pair fails at startup');
    my $ctx = Net::SSLeay::CTX_new();
    ok(eval { $c->apply_to_ctx($ctx); 1 }, 'existing object uses its validated pair after files change');
    Net::SSLeay::CTX_free($ctx);
}

done_testing;
