#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('PDF::Make::Crypt') }
BEGIN { use_ok('PDF::Make::Document') }

# ── Constructor ──────────────────────────────────────────

my $crypt = PDF::Make::Crypt->new;
ok($crypt, 'Crypt created');

# ── Setup AES-256 ────────────────────────────────────────

my $doc = PDF::Make::Document->new;
$doc->add_page(612, 792);

my $ok = eval { $crypt->setup('AES-256', 'userpass', 'ownerpass', 0xFFFFFFFC, $doc); 1 };
ok($ok, 'setup AES-256') or diag $@;

# ── Accessors ────────────────────────────────────────────

ok(defined $crypt->get_key_length, 'key_length defined');
ok($crypt->get_key_length > 0, 'key_length > 0');
ok(defined $crypt->get_permissions, 'permissions defined');
ok($crypt->is_authenticated, 'authenticated after setup');
ok(defined $crypt->get_encrypt_metadata, 'encrypt_metadata defined');

# ── Setup AES-128 ────────────────────────────────────────

my $crypt2 = PDF::Make::Crypt->new;
my $doc2 = PDF::Make::Document->new;
$doc2->add_page(612, 792);

$ok = eval { $crypt2->setup('AES-128', 'user', 'owner', 0x04, $doc2); 1 };
ok($ok, 'setup AES-128') or diag $@;
ok($crypt2->get_key_length >= 16, 'AES-128 key_length >= 16');

# ── Setup RC4-128 ────────────────────────────────────────

my $crypt3 = PDF::Make::Crypt->new;
my $doc3 = PDF::Make::Document->new;
$doc3->add_page(612, 792);

$ok = eval { $crypt3->setup('RC4-128', 'user', 'owner', 0xFFFFFFFC, $doc3); 1 };
ok($ok, 'setup RC4-128') or diag $@;

# ── Setup RC4-40 ─────────────────────────────────────────

my $crypt4 = PDF::Make::Crypt->new;
my $doc4 = PDF::Make::Document->new;
$doc4->add_page(612, 792);

$ok = eval { $crypt4->setup('RC4-40', 'user', 'owner', 0xFFFFFFFC, $doc4); 1 };
ok($ok, 'setup RC4-40') or diag $@;

done_testing;
