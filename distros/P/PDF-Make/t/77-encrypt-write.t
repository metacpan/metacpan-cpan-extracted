#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Builder') }

sub build_encrypted {
    my ($algo, $user, $owner) = @_;
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter')
      ->add_h1(text => 'Secret Title')
      ->add_text(text => 'Payload one.')
      ->add_text(text => 'Payload two.');
    $b->encrypt(
        algorithm      => $algo,
        user_password  => $user,
        owner_password => $owner // $user,
    );
    $b->save;
    return $f;
}

# ── AES-256 round-trip ───────────────────────────────────
{
    my $f = build_encrypted('AES-256', 'user', 'owner');

    open my $fh, '<:raw', $f or die $!;
    my $bytes = do { local $/; <$fh> };

    ok($bytes =~ /\/Encrypt\s+\d+\s+\d+\s+R/, 'AES-256: /Encrypt entry in trailer');
    ok($bytes =~ /\/Filter\s*\/Standard/,    'AES-256: /Filter /Standard in encrypt dict');
    ok($bytes =~ /\/V\s*5/,                  'AES-256: V=5');
    ok($bytes =~ /\/R\s*6/,                  'AES-256: R=6');
    ok(index($bytes, 'Payload one') < 0,     'AES-256: plaintext not leaked');
    ok(index($bytes, 'Secret Title') < 0,    'AES-256: h1 text not leaked');

    my $b = PDF::Make::Builder->open_existing($f, password => 'user');
    is($b->page_count, 1, 'AES-256: reopens with user password');

    my $res = $b->extract_structured($f, page => 0, password => 'user');
    my @w  = $res->text_positions;
    my $text = join(' ', map { $_->{text} } @w);
    like($text, qr/Payload one/, 'AES-256: decrypted content streams readable');
    like($text, qr/Secret/,       'AES-256: decrypted h1 readable');

    # Owner password also works
    my $b_owner = eval { PDF::Make::Builder->open_existing($f, password => 'owner') };
    ok($b_owner, 'AES-256: reopens with owner password');

    # Wrong password rejected
    eval { PDF::Make::Builder->open_existing($f, password => 'nope') };
    like($@, qr/authenticat|password|encrypt/i, 'AES-256: wrong password rejected');

    unlink $f;
}

# ── AES-128 round-trip ───────────────────────────────────
{
    my $f = build_encrypted('AES-128', 'aes128pw');
    open my $fh, '<:raw', $f or die $!;
    my $bytes = do { local $/; <$fh> };
    ok($bytes =~ /\/V\s*4/,  'AES-128: V=4');
    ok($bytes =~ /\/R\s*4/,  'AES-128: R=4');
    ok(index($bytes, 'Payload one') < 0, 'AES-128: plaintext not leaked');

    my $b = PDF::Make::Builder->open_existing($f, password => 'aes128pw');
    is($b->page_count, 1, 'AES-128: reopens with password');
    my $res = $b->extract_structured($f, page => 0, password => 'aes128pw');
    my $text = join(' ', map { $_->{text} } $res->text_positions);
    like($text, qr/Payload/, 'AES-128: decrypted content readable');

    unlink $f;
}

# ── RC4-128 round-trip ───────────────────────────────────
{
    my $f = build_encrypted('RC4-128', 'rc4pw');
    open my $fh, '<:raw', $f or die $!;
    my $bytes = do { local $/; <$fh> };
    ok($bytes =~ /\/V\s*2/,  'RC4-128: V=2');
    ok($bytes =~ /\/R\s*3/,  'RC4-128: R=3');
    ok(index($bytes, 'Payload one') < 0, 'RC4-128: plaintext not leaked');

    my $b = PDF::Make::Builder->open_existing($f, password => 'rc4pw');
    is($b->page_count, 1, 'RC4-128: reopens with password');
    my $res = $b->extract_structured($f, page => 0, password => 'rc4pw');
    my $text = join(' ', map { $_->{text} } $res->text_positions);
    like($text, qr/Payload/, 'RC4-128: decrypted content readable');

    unlink $f;
}

# ── Empty-string password works (user pw = "") ───────────
{
    my $f = build_encrypted('AES-256', '', 'adminonly');
    my $b = PDF::Make::Builder->open_existing($f);  # empty password attempt
    ok($b, 'empty user password opens without asking');
    unlink $f;
}

# ── No encryption → no /Encrypt in trailer (regression) ─
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page->add_text(text => 'plain');
    $b->save;
    open my $fh, '<:raw', $f or die $!;
    my $bytes = do { local $/; <$fh> };
    unlike($bytes, qr/\/Encrypt/, 'non-encrypted PDF has no /Encrypt');
    unlink $f;
}

done_testing;
