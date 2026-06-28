#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('PDF::Make::Crypt');
    use_ok('PDF::Make::Document');
    use_ok('PDF::Make::Canvas');
    use_ok('PDF::Make::Page', ':fonts');
}

# ── Create and encrypt a document ────────────────────────

my $doc = PDF::Make::Document->new;
$doc->title('Encryption Round-Trip');
my $page = $doc->add_page(612, 792);
$page->add_std14_font('F1', HELVETICA);
my $c = PDF::Make::Canvas->new;
$c->BT->Tf('F1', 12)->Td(72, 700)->Tj('Secret Message')->ET;
$page->set_content($c->to_bytes);

my $crypt = PDF::Make::Crypt->new;
ok($crypt, 'Crypt created');

# AES-256 setup
$crypt->setup('AES-256', 'user123', 'owner456', 0xFFFFFFFC, $doc);
ok($crypt->is_authenticated, 'authenticated after setup');
ok($crypt->is_owner, 'is owner after setup with owner pass');

# Key length
my $kl = $crypt->get_key_length;
ok($kl >= 32, "AES-256 key length >= 32: $kl");

# Permissions
my $perms = $crypt->get_permissions;
ok(defined $perms, 'permissions defined');

# Encrypt metadata flag
my $em = $crypt->get_encrypt_metadata;
ok(defined $em, 'encrypt_metadata defined');

# Set encrypt metadata
$crypt->set_encrypt_metadata(0);
is($crypt->get_encrypt_metadata, 0, 'encrypt_metadata set to 0');
$crypt->set_encrypt_metadata(1);
is($crypt->get_encrypt_metadata, 1, 'encrypt_metadata set back to 1');

# ── String encrypt/decrypt round-trip ────────────────────

my $plaintext = 'Hello, encrypted world!';
my $encrypted = eval { $crypt->encrypt_string(1, 0, $plaintext) };
ok(defined $encrypted, 'string encrypted');
ok($encrypted ne $plaintext, 'encrypted != plaintext');

my $decrypted = eval { $crypt->decrypt_string(1, 0, $encrypted) };
ok(defined $decrypted, 'string decrypted');
is($decrypted, $plaintext, 'decrypt round-trip matches');

# ── Stream encrypt/decrypt round-trip ────────────────────

my $stream_data = 'BT /F1 12 Tf 72 700 Td (Test) Tj ET';
my $enc_stream = eval { $crypt->encrypt_stream($stream_data, 2, 0) };
ok(defined $enc_stream, 'stream encrypted');

my $dec_stream = eval { $crypt->decrypt_stream($enc_stream, 2, 0) };
ok(defined $dec_stream, 'stream decrypted');
is($dec_stream, $stream_data, 'stream decrypt round-trip matches');

# ── Permission check ─────────────────────────────────────

# With 0xFFFFFFFC all permissions are granted
ok($crypt->has_permission(4), 'has print permission');

# ── Different algorithms ─────────────────────────────────

for my $algo ('AES-128', 'RC4-128', 'RC4-40') {
    my $d = PDF::Make::Document->new;
    $d->add_page(612, 792);
    my $cr = PDF::Make::Crypt->new;
    eval { $cr->setup($algo, 'u', 'o', 0xFFFFFFFC, $d) };
    ok(!$@, "setup $algo") or diag $@;
    ok($cr->is_authenticated, "$algo authenticated");
    ok($cr->get_key_length > 0, "$algo key_length > 0");
}

# ── Perl permission utilities ────────────────────────────

my $flags = PDF::Make::Crypt->parse_permissions(['print', 'copy', 'modify']);
ok($flags > 0, 'parse_permissions returns flags');

my @names = PDF::Make::Crypt->format_permissions($flags);
ok(scalar @names >= 3, 'format_permissions returns names');
ok((grep { $_ eq 'print' } @names), 'format has print');
ok((grep { $_ eq 'copy' } @names), 'format has copy');

my $all_flags = PDF::Make::Crypt->parse_permissions(undef);
ok($all_flags > 0, 'undef permissions = PERM_ALL');

my $zero = PDF::Make::Crypt->parse_permissions([]);
is($zero, 0, 'empty array = 0');

my @all_names = PDF::Make::Crypt->format_permissions(0xFFFFFFFC);
ok(scalar @all_names >= 4, 'full flags format to 4+ names');

# ── Test with fixture ────────────────────────────────────

SKIP: {
    skip 'encrypted fixture not found', 2 unless -f 't/fixtures/fixtures/encrypted_aes256.pdf';

    open my $fh, '<:raw', 't/fixtures/fixtures/encrypted_aes256.pdf';
    my $bytes = do { local $/; <$fh> };
    ok(length($bytes) > 100, 'encrypted fixture loaded');
    like($bytes, qr/%PDF/, 'fixture is a PDF');
}

done_testing;
