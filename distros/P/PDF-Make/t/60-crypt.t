#!/usr/bin/env perl
#
# t/60-crypt.t — PDF encryption/decryption tests
#

use strict;
use warnings;
use Test::More tests => 23;

# Test 1: Module loads
use_ok('PDF::Make');
use_ok('PDF::Make::Crypt');

# Test 2: Create Crypt object
{
    my $crypt = PDF::Make::Crypt->new();
    ok(defined $crypt, 'Crypt object created');
    isa_ok($crypt, 'PDF::Make::Crypt');
}

# Generate a dummy document ID for testing
my $doc_id = pack('H*', '0123456789abcdef0123456789abcdef');  # 16 bytes

# Test 3: Setup encryption with RC4-40
{
    my $crypt = PDF::Make::Crypt->new();
    my $result = $crypt->setup('RC4-40', 'user', 'owner', 0xFFFFFFFC, $doc_id);
    ok($result, 'RC4-40 setup succeeded');
    ok($crypt->is_authenticated(), 'RC4-40 is authenticated after setup');
    ok($crypt->is_owner(), 'RC4-40 is owner after setup');
}

# Test 4: Setup encryption with RC4-128
{
    my $crypt = PDF::Make::Crypt->new();
    my $result = $crypt->setup('RC4-128', 'password', 'secret', 0xFFFFFFFC, $doc_id);
    ok($result, 'RC4-128 setup succeeded');
    ok($crypt->is_authenticated(), 'RC4-128 is authenticated');
}

# Test 5: Setup encryption with AES-128
{
    my $crypt = PDF::Make::Crypt->new();
    my $result = $crypt->setup('AES-128', 'aesuser', 'aesowner', 0xFFFFFFFC, $doc_id);
    ok($result, 'AES-128 setup succeeded');
    ok($crypt->is_authenticated(), 'AES-128 is authenticated');
}

# Test 6: Setup encryption with AES-256
{
    my $crypt = PDF::Make::Crypt->new();
    my $result = $crypt->setup('AES-256', 'strong', 'stronger', 0xFFFFFFFC, $doc_id);
    ok($result, 'AES-256 setup succeeded');
    ok($crypt->is_authenticated(), 'AES-256 is authenticated');
}

# Test 7: Empty user password (allow opening without password)
{
    my $crypt = PDF::Make::Crypt->new();
    my $result = $crypt->setup('RC4-128', '', 'onlyowner', 0xFFFFFFFC, $doc_id);
    ok($result, 'Empty user password setup succeeded');
}

# Test 8: Encrypt/decrypt roundtrip with RC4
{
    my $crypt = PDF::Make::Crypt->new();
    $crypt->setup('RC4-128', 'test', 'test', 0xFFFFFFFC, $doc_id);
    
    my $plaintext = "Hello, encrypted world!";
    
    my $encrypted = $crypt->encrypt_string(1, 0, $plaintext);
    ok(defined $encrypted, 'String encrypted');
    isnt($encrypted, $plaintext, 'Encrypted differs from plaintext');
    
    my $decrypted = $crypt->decrypt_string(1, 0, $encrypted);
    is($decrypted, $plaintext, 'RC4 decrypt roundtrip successful');
}

# Test 9: Encrypt/decrypt roundtrip with AES-128
{
    my $crypt = PDF::Make::Crypt->new();
    $crypt->setup('AES-128', 'aes', 'aes', 0xFFFFFFFC, $doc_id);
    
    my $plaintext = "AES encrypted content";
    
    my $encrypted = $crypt->encrypt_string(5, 0, $plaintext);
    ok(defined $encrypted, 'AES string encrypted');
    
    my $decrypted = $crypt->decrypt_string(5, 0, $encrypted);
    is($decrypted, $plaintext, 'AES-128 decrypt roundtrip successful');
}

# Test 10: Permissions
{
    my $crypt = PDF::Make::Crypt->new();
    # Permission flags: print=4, modify=8, copy=16, annotate=32
    my $perms = PDF::Make::Crypt::PERM_PRINT() | PDF::Make::Crypt::PERM_COPY();
    $crypt->setup('RC4-128', 'user', 'owner', $perms | 0xFFFFF0C0, $doc_id);
    
    ok($crypt->has_permission(PDF::Make::Crypt::PERM_PRINT()), 'Has print permission');
    ok($crypt->has_permission(PDF::Make::Crypt::PERM_COPY()), 'Has copy permission');
}

# Test 11: Stream encryption with AES
{
    my $crypt = PDF::Make::Crypt->new();
    $crypt->setup('AES-256', 'stream', 'stream', 0xFFFFFFFC, $doc_id);
    
    my $stream_data = "BT /F1 12 Tf 100 700 Td (Test) Tj ET";
    
    my $encrypted = $crypt->encrypt_stream($stream_data, 10, 0);
    ok(defined $encrypted, 'Stream encrypted with AES');
    
    my $decrypted = $crypt->decrypt_stream($encrypted, 10, 0);
    is($decrypted, $stream_data, 'AES stream decrypt roundtrip successful');
}
