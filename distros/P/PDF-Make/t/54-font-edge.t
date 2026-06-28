#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('PDF::Make') }
BEGIN { use_ok('PDF::Make::Font') }
BEGIN { use_ok('PDF::Make::Arena') }
BEGIN { use_ok('PDF::Make::Page', ':fonts') }

# ── Font::new error path ───────────────────────────────

eval { PDF::Make::Font->new() };
like($@, qr/must specify file, bytes, or standard14/,
    'Font->new with no args croaks');

# ── Font::new with std14 key ──────────────────────────

{
    my $arena = PDF::Make::Arena->new;
    my $f = PDF::Make::Font->new(standard14 => 'Helvetica', arena => $arena);
    ok($f, 'Font->new with standard14 key');
    ok($f->is_standard14, 'is_standard14 true');
    ok(!$f->is_truetype, 'is_truetype false for std14');
}

# ── Font::new with std14 alias ────────────────────────

{
    my $arena = PDF::Make::Arena->new;
    my $f = PDF::Make::Font->new(std14 => 'Courier', arena => $arena);
    ok($f, 'Font->new with std14 alias');
    ok($f->is_standard14, 'std14 alias is_standard14');
}

# ── is_truetype for TrueType font ────────────────────

SKIP: {
    my @ttf = glob('t/fixtures/fonts/*.ttf');
    skip 'No TTF fonts in fixtures', 2 unless @ttf;

    my $arena = PDF::Make::Arena->new;
    my $f = PDF::Make::Font->new(file => $ttf[0], arena => $arena);
    ok($f, 'TrueType font loaded');
    ok($f->is_truetype, 'is_truetype true for TTF');
}

# ── All 14 standard fonts ────────────────────────────

my @std14 = @PDF::Make::Font::STD14_NAMES;
is(scalar @std14, 14, '14 standard font names');

for my $name (@std14) {
    my $arena = PDF::Make::Arena->new;
    my $f = eval { PDF::Make::Font->new(standard14 => $name, arena => $arena) };
    ok($f, "standard14 '$name' loads") or diag $@;
}

# ── Font type constants ──────────────────────────────

is(PDF::Make::Font::TYPE_TYPE1, 0, 'TYPE_TYPE1 = 0');
is(PDF::Make::Font::TYPE_TRUETYPE, 1, 'TYPE_TRUETYPE = 1');
is(PDF::Make::Font::TYPE_CID_TRUETYPE, 2, 'TYPE_CID_TRUETYPE = 2');

done_testing;
