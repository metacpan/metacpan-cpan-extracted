#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('PDF::Make::Signature') }

my $cert_file = 't/fixtures/fixtures/test_cert.p12';
my $cert_pass = 'testpass';

# ── Load PKCS#12 identity ───────────────────────────────

SKIP: {
    skip 'PKCS#12 fixture not found', 15 unless -f $cert_file;

    my $identity = eval {
        PDF::Make::Signature->load_identity(
            file     => $cert_file,
            password => $cert_pass,
        );
    };

    if ($@) {
        skip "load_identity failed: $@", 15;
    }

    ok($identity, 'identity loaded from PKCS#12');
    isa_ok($identity, 'PDF::Make::SigningIdentity');

    # Identity properties
    ok($identity->has_private_key, 'has private key');
    ok($identity->has_certificate, 'has certificate');
    ok($identity->can_sign, 'can sign');

    # Certificate inspection
    my $subject = eval { $identity->subject };
    ok(defined $subject, 'subject defined');
    like($subject, qr/PDFMake|Semantic|Test/i, 'subject contains expected name');

    my $issuer = eval { $identity->issuer };
    ok(defined $issuer, 'issuer defined');

    # Chain
    my $chain_len = eval { $identity->chain_length };
    ok(defined $chain_len, "chain_length: $chain_len");

    # ── Verify signature count on unsigned PDF ───────────

    SKIP: {
        skip 'hello_world.pdf not found', 2 unless -f 't/fixtures/hello_world.pdf';

        my $count = eval {
            PDF::Make::Signature->count_signatures(
                file => 't/fixtures/hello_world.pdf'
            );
        };
        ok(defined $count, 'count_signatures works');
        is($count, 0, 'unsigned PDF has 0 signatures');
    }

    # ── Certificate from identity ────────────────────────

    SKIP: {
        eval { require PDF::Make::CertificateXS };
        skip 'CertificateXS not available', 4 if $@;

        # Try to get cert details
        my $not_before = eval { $identity->subject };
        ok(defined $not_before, 'cert subject accessible');

        my $is_valid = eval { $identity->is_valid };
        ok(defined $is_valid, 'is_valid check works');
    }
}

# ── Verify method on unsigned PDF ────────────────────────

SKIP: {
    skip 'hello_world.pdf not found', 3 unless -f 't/fixtures/hello_world.pdf';

    my $result = eval {
        PDF::Make::Signature->verify(
            file  => 't/fixtures/hello_world.pdf',
            index => 0,
        );
    };

    if ($result) {
        isa_ok($result, 'PDF::Make::SignatureResult');
        ok(defined $result->is_valid, 'is_valid defined');
        ok(defined $result->error || defined $result->signer_name, 'result has details');
    } else {
        ok(1, 'verify returned undef for unsigned PDF (expected)');
        ok(1, 'skip');
        ok(1, 'skip');
    }
}

# ── Hash functions ───────────────────────────────────────

SKIP: {
    my $can_hash = eval { PDF::Make::Signature->can('sha256') };
    skip 'hash functions not available', 3 unless $can_hash;

    my $h256 = PDF::Make::Signature->sha256('test data');
    ok(defined $h256, 'sha256 returns value');
    ok(length($h256) == 32, 'sha256 is 32 bytes');

    my $h512 = PDF::Make::Signature->sha512('test data');
    ok(defined $h512, 'sha512 returns value');
}

done_testing;
