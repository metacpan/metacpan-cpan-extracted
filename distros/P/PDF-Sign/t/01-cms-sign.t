use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Basename qw(dirname);
use File::Spec;

# skip entire test if openssl not available
my $quiet = ($^O eq 'MSWin32' ? '2>nul' : '2>/dev/null');
my $openssl = `openssl version $quiet`;
plan skip_all => 'openssl not available' unless $openssl =~ /SSL/;

use PDF::Sign qw(config cms_sign);

my $tmpdir = tempdir(CLEANUP => 1);
my $cert   = "$tmpdir/cert.pem";
my $key    = "$tmpdir/key.pem";
my $infile = "$tmpdir/input.pdf";
my $tdir    = dirname(__FILE__);
my $cnf     = File::Spec->catfile($tdir, 'openssl.cnf');

# ============================================================
# generate self-signed certificate for testing
# ============================================================
my $gen = system(
    'openssl', 'req', '-x509', '-newkey', 'rsa:2048',
    '-keyout', $key,
    '-out',    $cert,
    '-days',   '1',
    '-nodes',
    '-subj',   '/C=IT/O=PDF-Sign-Test/CN=PDF-Sign Test Certificate',
    '-config', $cnf
);
plan skip_all => 'openssl could not generate test certificate' if $gen != 0;
ok(-e $cert, 'self-signed certificate generated');
ok(-e $key,  'private key generated');

# ============================================================
# create a minimal fake PDF input
# ============================================================
open(my $fh, '>:raw', $infile) or die "Cannot write: $!";
print $fh "%PDF-1.4\nfake PDF content for signing test\n%%EOF\n";
close $fh;

# ============================================================
# configure PDF::Sign
# ============================================================
config(
    osslcmd     => 'openssl',
    x509_pem    => $cert,
    privkey_pem => $key,
    tmpdir      => $tmpdir,
);

# ============================================================
# test cms_sign
# ============================================================
my $signature = eval {
    cms_sign(
        signer => $cert,
        inkey  => $key,
        in     => $infile,
    )
};
ok(!$@,                        'cms_sign did not die')           or diag "Error: $@";
ok(defined $signature,         'cms_sign returned a value');
ok(length($signature) > 0,     'cms_sign returned non-empty signature');

SKIP: {
    skip 'no signature to inspect', 2 unless defined $signature && length $signature;

    # DER SEQUENCE starts with 0x30
    my $first_byte = ord(substr($signature, 0, 1));
    is($first_byte, 0x30, 'signature is valid DER (starts with SEQUENCE 0x30)');

    # sanity: RSA 2048 signature should be at least 256 bytes
    ok(length($signature) >= 256, 'signature length is plausible (>= 256 bytes)');
}

# ============================================================
# test _cert_subject extraction
# ============================================================
my $subject = eval { PDF::Sign::_cert_subject($cert) };
ok(!$@,          '_cert_subject did not die')          or diag "Error: $@";
ok(defined $subject && length($subject) > 0,
                 '_cert_subject returned non-empty string');
like($subject,   qr/PDF-Sign-Test/,
                 '_cert_subject contains expected organization');

diag "openssl version: " . (split /\n/, $openssl)[0];
diag "subject extracted: $subject" if defined $subject;

done_testing();
