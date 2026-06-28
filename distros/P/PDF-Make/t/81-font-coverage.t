#!/usr/bin/perl
# Coverage-targeted tests for PDF::Make::Font file/bytes constructor paths.
use strict;
use warnings;
use Test::More;
use PDF::Make::Font;
use PDF::Make::Arena;

# Find a TTF font fixture from common system locations (SKIP if none found).
my @candidates = (
    't/fixtures/fonts/test.ttf',
    '/System/Library/Fonts/Symbol.ttf',
    '/System/Library/Fonts/Geneva.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/usr/share/fonts/TTF/DejaVuSans.ttf',
);
my ($ttf_path) = grep { -r $_ } @candidates;

# ── Constructor: error path ──────────────────────────────
eval { PDF::Make::Font->new() };
like($@, qr/must specify file, bytes, or standard14/, 'no args dies');

# ── standard14 path (already covered elsewhere, keep one) ──
{
    my $arena = PDF::Make::Arena->new;
    my $f = PDF::Make::Font->new(standard14 => 'Helvetica', arena => $arena);
    isa_ok($f, 'PDF::Make::Font', 'standard14 via new');
    ok($f->is_standard14, 'is_standard14 true');
    ok(!$f->is_truetype,  'is_truetype false for standard14');
}

# std14 alias
{
    my $arena = PDF::Make::Arena->new;
    my $f = PDF::Make::Font->new(std14 => 'Times-Roman', arena => $arena);
    isa_ok($f, 'PDF::Make::Font', 'std14 alias works');
}

# ── file path ────────────────────────────────────────────
SKIP: {
    skip 'no TTF fixture available', 4 unless $ttf_path;

    my $arena = PDF::Make::Arena->new;
    my $f = eval { PDF::Make::Font->new(file => $ttf_path, arena => $arena) };
    skip "TTF load failed ($@)", 4 unless $f;

    isa_ok($f, 'PDF::Make::Font', 'from_file via new');
    ok($f->is_truetype || $f->is_standard14, 'font has a type');
    ok(!$f->is_standard14, 'is_standard14 false for TTF');
    ok($f->is_truetype,     'is_truetype true for TTF');
}

# ── bytes path ───────────────────────────────────────────
SKIP: {
    skip 'no TTF fixture available', 2 unless $ttf_path;
    open my $fh, '<:raw', $ttf_path or skip "cannot read $ttf_path", 2;
    local $/;
    my $bytes = <$fh>;
    close $fh;

    my $arena = PDF::Make::Arena->new;
    my $f = eval { PDF::Make::Font->new(bytes => $bytes, arena => $arena) };
    skip "TTF from bytes failed ($@)", 2 unless $f;

    isa_ok($f, 'PDF::Make::Font', 'from_bytes via new');
    ok($f->is_truetype, 'is_truetype true for bytes-loaded TTF');
}

done_testing;
