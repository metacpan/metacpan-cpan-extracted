#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Builder') }

my $f = tmpnam() . '.pdf';
END { unlink $f if $f && -f $f }

my $b = PDF::Make::Builder->new(file_name => $f);
$b->add_page(page_size => 'Letter');

# ── Radio group with options ─────────────────────────────

isa_ok($b->add_field(
    type       => 'radio',
    name       => 'color_choice',
    label      => 'Favorite Color',
    options    => ['Red', 'Green', 'Blue'],
), 'PDF::Make::Builder', 'radio field created');

# ── Radio with custom spacing ────────────────────────────

isa_ok($b->add_field(
    type       => 'radio',
    name       => 'size_choice',
    label      => 'Size',
    options    => ['Small', 'Medium', 'Large', 'XL'],
    spacing    => 20,
), 'PDF::Make::Builder', 'radio with spacing');

# ── Radio without label ─────────────────────────────────

isa_ok($b->add_field(
    type       => 'radio',
    name       => 'yesno',
    options    => ['Yes', 'No'],
), 'PDF::Make::Builder', 'radio without label');

# ── Save and verify ──────────────────────────────────────

$b->save;
ok(-f $f, 'radio PDF created');
ok(-s $f > 500, 'PDF has content');

open my $fh, '<:raw', $f;
my $bytes = do { local $/; <$fh> };
like($bytes, qr/AcroForm/, 'PDF has AcroForm');
like($bytes, qr/color_choice/, 'radio field name in PDF');
like($bytes, qr/size_choice/, 'second radio in PDF');

done_testing;
