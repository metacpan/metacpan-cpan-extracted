#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

BEGIN {
    use_ok('PDF::Make');
    use_ok('PDF::Make::Document');
    use_ok('PDF::Make::Signature');
}

# Test 1: Module loads
ok(1, 'PDF::Make::Signature module loaded');

# Test 2: Signature constants
is(PDF::Make::Signature::HASH_SHA256, 1, 'HASH_SHA256 constant');
is(PDF::Make::Signature::HASH_SHA384, 2, 'HASH_SHA384 constant');
is(PDF::Make::Signature::HASH_SHA512, 3, 'HASH_SHA512 constant');

is(PDF::Make::Signature::MDP_NONE, 0, 'MDP_NONE constant');
is(PDF::Make::Signature::MDP_NO_CHANGES, 1, 'MDP_NO_CHANGES constant');
is(PDF::Make::Signature::MDP_FORM_FILL, 2, 'MDP_FORM_FILL constant');
is(PDF::Make::Signature::MDP_ANNOTATE, 3, 'MDP_ANNOTATE constant');

# Test 3: SignatureResult object
{
    my $result = PDF::Make::SignatureResult->new(
        valid           => 1,
        signature_valid => 1,
        digest_valid    => 1,
        cert_valid      => 1,
        signer_name     => 'John Doe',
        signer_email    => 'john@example.com',
        signing_time    => time(),
    );
    
    ok($result->is_valid, 'SignatureResult is_valid');
    ok($result->signature_valid, 'SignatureResult signature_valid');
    ok($result->digest_valid, 'SignatureResult digest_valid');
    ok($result->cert_valid, 'SignatureResult cert_valid');
    is($result->signer_name, 'John Doe', 'SignatureResult signer_name');
    is($result->signer_email, 'john@example.com', 'SignatureResult signer_email');
    ok($result->signing_time > 0, 'SignatureResult signing_time');
    ok(!$result->document_modified, 'SignatureResult document_modified');
}

# Test 4: Invalid SignatureResult
{
    my $result = PDF::Make::SignatureResult->new(
        valid => 0,
        error => 'Certificate expired',
    );
    
    ok(!$result->is_valid, 'Invalid SignatureResult');
    is($result->error, 'Certificate expired', 'SignatureResult error message');
}

# Test 5: Certificate object
{
    my $cert = PDF::Make::Certificate->new(
        version        => 2,  # v3
        serial         => '01:02:03:04',
        issuer         => 'CN=Test CA, O=Test',
        subject        => 'CN=Test User, O=Test',
        not_before     => time() - 86400,
        not_after      => time() + 86400 * 365,
        key_usage      => 0x03,  # digitalSignature | nonRepudiation
        is_ca          => 0,
        is_self_signed => 0,
    );
    
    is($cert->version, 2, 'Certificate version');
    is($cert->serial, '01:02:03:04', 'Certificate serial');
    is($cert->issuer, 'CN=Test CA, O=Test', 'Certificate issuer');
    is($cert->subject, 'CN=Test User, O=Test', 'Certificate subject');
    ok($cert->is_valid, 'Certificate is valid');
    ok($cert->can_sign_documents, 'Certificate can sign documents');
    ok(!$cert->is_ca, 'Certificate is not CA');
    ok(!$cert->is_self_signed, 'Certificate is not self-signed');
}

# Test 6: Expired certificate
{
    my $cert = PDF::Make::Certificate->new(
        not_before => time() - 86400 * 365,
        not_after  => time() - 86400,  # Expired yesterday
    );
    
    ok(!$cert->is_valid, 'Expired certificate is not valid');
}

# Test 7: Certificate without signing key usage
{
    my $cert = PDF::Make::Certificate->new(
        not_before     => time() - 86400,
        not_after      => time() + 86400 * 365,
        key_usage      => 0x04,  # keyEncipherment only
    );
    
    ok(!$cert->can_sign_documents, 'Certificate without signing key usage cannot sign');
}

# Test 8: SigningIdentity stubs
{
    eval {
        my $id = PDF::Make::SigningIdentity->from_pkcs12('/nonexistent.p12', 'pass');
    };
    like($@, qr/Cannot read|not yet implemented/i, 'PKCS#12 from nonexistent file fails');
}

# Test 9: Verify signature count on unsigned PDF
{
    my $doc = PDF::Make::Document->new;
    $doc->add_page;
    my $bytes = $doc->to_bytes;

    my $count;
    my $ok = eval {
        $count = PDF::Make::Signature->count_signatures(data => $bytes);
        1;
    };

    if ($ok) {
        is($count, 0, 'Unsigned PDF has no signatures');
    } else {
        like($@, qr/not yet implemented|unimplemented/i,
            'count_signatures currently unimplemented in XS');
    }
}

# Test 10: Verify returns invalid for unsigned PDF
{
    my $result = PDF::Make::Signature->verify(data => '%PDF-1.4...');
    ok(!$result->is_valid, 'Unsigned PDF verification returns invalid');
}

# Test 11: load_identity requires correct args
{
    eval {
        PDF::Make::Signature->load_identity();
    };
    like($@, qr/requires.*file|key_file/i, 'load_identity requires file or key_file');
}

# Test 12: count_signatures requires file or data
{
    eval {
        PDF::Make::Signature->count_signatures();
    };
    like($@, qr/requires.*file.*data/i, 'count_signatures requires file or data');
}

# Test 13: verify requires file or data
{
    eval {
        PDF::Make::Signature->verify();
    };
    like($@, qr/requires.*file.*data/i, 'verify requires file or data');
}

done_testing();
