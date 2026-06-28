#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Signature') }

# ── PDF::Make::Certificate ──────────────────────────────

my $now = time();
my $cert = PDF::Make::Certificate->new(
    version        => 3,
    serial         => '0A:1B:2C',
    issuer         => 'CN=Test CA',
    subject        => 'CN=Test Signer',
    not_before     => $now - 86400,
    not_after      => $now + 86400 * 365,
    key_usage      => 0x03,         # digitalSignature | nonRepudiation
    ext_key_usage  => 0xFC,
    is_ca          => 0,
    is_self_signed => 1,
);
isa_ok($cert, 'PDF::Make::Certificate');

# Accessors
is($cert->version, 3, 'cert version');
is($cert->serial, '0A:1B:2C', 'cert serial');
is($cert->issuer, 'CN=Test CA', 'cert issuer');
is($cert->subject, 'CN=Test Signer', 'cert subject');
ok($cert->not_before < $now, 'cert not_before');
ok($cert->not_after > $now, 'cert not_after');
is($cert->key_usage, 0x03, 'cert key_usage');
is($cert->ext_key_usage, 0xFC, 'cert ext_key_usage');
is($cert->is_ca, 0, 'cert is_ca');
is($cert->is_self_signed, 1, 'cert is_self_signed');

# is_valid
ok($cert->is_valid, 'cert currently valid');
ok($cert->is_valid($now), 'cert valid at now');
ok(!$cert->is_valid($now - 86400 * 2), 'cert not valid before not_before');
ok(!$cert->is_valid($now + 86400 * 400), 'cert not valid after not_after');

# can_sign_documents
ok($cert->can_sign_documents, 'cert can sign (good key_usage)');

# cert with bad key_usage (no digitalSignature/nonRepudiation)
my $bad_ku = PDF::Make::Certificate->new(
    key_usage     => 0x04,  # only keyEncipherment
    ext_key_usage => 0,
    not_before    => $now - 86400,
    not_after     => $now + 86400,
);
ok(!$bad_ku->can_sign_documents, 'cert cannot sign (bad key_usage)');

# cert with bad ext_key_usage
my $bad_eku = PDF::Make::Certificate->new(
    key_usage     => 0,
    ext_key_usage => 0x01,  # not in 0xFC mask
    not_before    => $now - 86400,
    not_after     => $now + 86400,
);
ok(!$bad_eku->can_sign_documents, 'cert cannot sign (bad ext_key_usage)');

# cert with no key_usage or ext_key_usage (permissive)
my $perm = PDF::Make::Certificate->new(
    not_before => $now - 86400,
    not_after  => $now + 86400,
);
ok($perm->can_sign_documents, 'cert with no usage flags can sign');

# load error paths
eval { PDF::Make::Certificate->load() };
like($@, qr/load requires/, 'load without args dies');

eval { PDF::Make::Certificate->load(file => '/nonexistent/cert.pem') };
ok($@, 'load with missing file dies');

eval { PDF::Make::Certificate->load(data => '-----BEGIN CERTIFICATE-----') };
like($@, qr/not yet implemented/, 'PEM parsing stub dies');

eval { PDF::Make::Certificate->load(data => "\x30\x82") };
like($@, qr/not yet implemented/, 'DER parsing stub dies');

# ── PDF::Make::SignatureResult ──────────────────────────

my $result = PDF::Make::SignatureResult->new(
    valid             => 1,
    signature_valid   => 1,
    digest_valid      => 1,
    cert_valid        => 1,
    timestamp_valid   => 1,
    document_modified => 0,
    signer_name       => 'Test User',
    signer_email      => 'test@example.com',
    signing_time      => $now,
    cert              => $cert,
    chain             => [$cert],
    error             => undef,
);
ok($result->is_valid, 'result is valid');
ok($result->signature_valid, 'signature valid');
ok($result->digest_valid, 'digest valid');
ok($result->cert_valid, 'cert valid');
ok($result->timestamp_valid, 'timestamp valid');
is($result->document_modified, 0, 'not modified');
is($result->signer_name, 'Test User', 'signer name');
is($result->signer_email, 'test@example.com', 'signer email');
is($result->signing_time, $now, 'signing time');
isa_ok($result->certificate, 'PDF::Make::Certificate');
is(ref($result->certificate_chain), 'ARRAY', 'chain is array');
is($result->error, undef, 'no error');

# Default result
my $default_r = PDF::Make::SignatureResult->new();
is($default_r->is_valid, 0, 'default not valid');
is($default_r->document_modified, 0, 'default not modified');

# ── PDF::Make::SigningIdentity (pure Perl) ──────────────

my $identity = PDF::Make::SigningIdentity->new(
    cert    => $cert,
    privkey => 'fake_key',
    chain   => [$cert],
);
isa_ok($identity, 'PDF::Make::SigningIdentity');

# ── PDF::Make::Signature error paths ────────────────────

eval { PDF::Make::Signature->load_identity() };
like($@, qr/load_identity requires/, 'load_identity no args dies');

eval { PDF::Make::Signature->verify() };
like($@, qr/verify requires/, 'verify no args dies');

eval { PDF::Make::Signature->count_signatures() };
like($@, qr/count_signatures requires/, 'count_signatures no args dies');

# verify with data (uses _verify stub which returns result)
my $v = PDF::Make::Signature->verify(data => '%PDF-1.4 test');
isa_ok($v, 'PDF::Make::SignatureResult', 'verify with data returns result');

# count with data
my $c = PDF::Make::Signature->count_signatures(data => '%PDF-1.4 test');
is($c, 0, 'count_signatures with data returns 0');

# verify with file
my $tf = tmpnam() . '.pdf';
open my $fh, '>:raw', $tf or die $!;
print $fh '%PDF-1.4 test data';
close $fh;
my $v2 = PDF::Make::Signature->verify(file => $tf);
isa_ok($v2, 'PDF::Make::SignatureResult', 'verify with file');
my $c2 = PDF::Make::Signature->count_signatures(file => $tf);
is($c2, 0, 'count_signatures with file');
unlink $tf;

# from_pkcs12 error paths
eval { PDF::Make::SigningIdentity->from_pkcs12() };
like($@, qr/PKCS.*12 file required/, 'from_pkcs12 no file dies');

eval { PDF::Make::SigningIdentity->from_pkcs12('/nonexistent.p12') };
like($@, qr/Cannot read/, 'from_pkcs12 missing file dies');

# from_files error paths
eval { PDF::Make::SigningIdentity->from_files() };
like($@, qr/key_file required/, 'from_files no key_file dies');

eval { PDF::Make::SigningIdentity->from_files(key_file => 'x') };
like($@, qr/cert_file required/, 'from_files no cert_file dies');

# _parse_files stub
eval { PDF::Make::SigningIdentity->_parse_files('k', 'c', '', '') };
like($@, qr/not yet implemented/, '_parse_files stub dies');

# from_files full file-reading path (still croaks via _parse_files stub)
{
    my $kf = tmpnam(); my $cf = tmpnam(); my $cc = tmpnam();
    for my $p ([$kf, "KEYDATA\n"], [$cf, "CERTDATA\n"], [$cc, "CHAINDATA\n"]) {
        open my $fh, '>:raw', $p->[0] or die $!;
        print $fh $p->[1]; close $fh;
    }
    eval {
        PDF::Make::SigningIdentity->from_files(
            key_file   => $kf,
            cert_file  => $cf,
            chain_file => $cc,
            password   => 'secret',
        );
    };
    like($@, qr/not yet implemented/, 'from_files full path reaches _parse_files stub');
    unlink $kf, $cf, $cc;
}

# load_identity with key_file/cert_file path
{
    my $kf = tmpnam(); my $cf = tmpnam();
    for my $p ([$kf, "K\n"], [$cf, "C\n"]) {
        open my $fh, '>:raw', $p->[0] or die $!;
        print $fh $p->[1]; close $fh;
    }
    eval {
        PDF::Make::Signature->load_identity(
            key_file  => $kf,
            cert_file => $cf,
            password  => 'x',
        );
    };
    like($@, qr/not yet implemented/, 'load_identity key_file path reaches stub');
    unlink $kf, $cf;
}

# Certificate->load with file path
{
    my $pf = tmpnam();
    open my $fh, '>:raw', $pf or die $!;
    print $fh "-----BEGIN CERTIFICATE-----\nfake-base64\n-----END CERTIFICATE-----\n";
    close $fh;
    eval { PDF::Make::Certificate->load(file => $pf) };
    like($@, qr/not yet implemented/, 'Certificate->load(file=>...) reads then stubs');
    unlink $pf;
}

# Signature::verify with nonexistent file path hits the error branch
{
    eval { PDF::Make::Signature->verify(file => '/nonexistent/absolutely/not.pdf') };
    like($@, qr/Cannot open/, 'verify nonexistent file croaks');
    eval { PDF::Make::Signature->count_signatures(file => '/nonexistent/absolutely/not.pdf') };
    like($@, qr/Cannot open/, 'count_signatures nonexistent file croaks');
}

# SignatureResult with all defaults
{
    my $r = PDF::Make::SignatureResult->new(valid => 1);
    is($r->is_valid,          1, 'result is_valid=1');
    is($r->signature_valid,   0, 'default signature_valid=0');
    is($r->cert_valid,        0, 'default cert_valid=0');
    is($r->timestamp_valid,   undef, 'default timestamp_valid undef');
    is($r->certificate,       undef, 'default certificate undef');
    is($r->certificate_chain, undef, 'default chain undef');
}

# ── Internal stub direct calls ───────────────────────────
{
    # _add_field stub: always croaks
    eval { PDF::Make::Signature::_add_field(undef, 'Sig1', 1, [0,0,100,100]) };
    like($@, qr/not yet implemented/, '_add_field stub croaks');

    # _add_signature_field with defaults: calls _add_field → croaks
    eval { PDF::Make::Signature::_add_signature_field(undef) };
    like($@, qr/not yet implemented/, '_add_signature_field stub croaks');

    eval { PDF::Make::Signature::_add_signature_field(undef,
        name => 'Sig', page => 2, rect => [10, 20, 30, 40]) };
    like($@, qr/not yet implemented/, '_add_signature_field with args still croaks');

    # _sign_document validation: no identity
    eval { PDF::Make::Signature::_sign_document(undef) };
    like($@, qr/requires 'identity'/, '_sign_document needs identity');

    # _sign_document with wrong-type identity
    eval { PDF::Make::Signature::_sign_document(undef, identity => 'not-an-object') };
    like($@, qr/must be a PDF::Make::SigningIdentity/, '_sign_document rejects non-object');

    # _sign_document with non-Signature blessed
    my $wrong = bless {}, 'SomeOtherClass';
    eval { PDF::Make::Signature::_sign_document(undef, identity => $wrong) };
    like($@, qr/must be a PDF::Make::SigningIdentity/, '_sign_document rejects wrong class');

    # _sign without identity config
    eval { PDF::Make::Signature::_sign(undef, {}) };
    like($@, qr/requires identity/, '_sign needs identity in config');
}

# ── Certificate::is_valid default-time path ──────────────
{
    my $now = time();
    my $c = PDF::Make::Certificate->new(
        not_before => $now - 100, not_after => $now + 100);
    ok($c->is_valid, 'is_valid without explicit time uses current time');
}

done_testing;
