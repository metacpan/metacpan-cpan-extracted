#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Builder') }

my $tmpfile = tmpnam() . '.pdf';
END { unlink $tmpfile if $tmpfile && -f $tmpfile }

my $b = PDF::Make::Builder->new(file_name => $tmpfile);
$b->add_page(page_size => 'Letter');

# ── Text field ───────────────────────────────────────────

isa_ok($b->add_field(
    type       => 'text',
    name       => 'name',
    label      => 'Full Name',
    w          => 300,
), 'PDF::Make::Builder', 'text field');

isa_ok($b->add_field(
    type          => 'text',
    name          => 'email',
    label         => 'Email',
    w             => 300,
    default_value => 'test@example.com',
), 'PDF::Make::Builder', 'text field with default');

isa_ok($b->add_field(
    type       => 'text',
    name       => 'bio',
    label      => 'Biography',
    w          => 400,
    h          => 60,
    multiline  => 1,
), 'PDF::Make::Builder', 'multiline text field');

# ── Checkbox ─────────────────────────────────────────────

isa_ok($b->add_field(
    type       => 'checkbox',
    name       => 'agree',
    label      => 'I agree to the terms',
), 'PDF::Make::Builder', 'checkbox');

isa_ok($b->add_field(
    type       => 'checkbox',
    name       => 'news',
    label      => 'Subscribe to newsletter',
    on_value   => 'Subscribed',
), 'PDF::Make::Builder', 'checkbox custom on_value');

# ── Combo (dropdown) ─────────────────────────────────────

isa_ok($b->add_field(
    type       => 'combo',
    name       => 'country',
    label      => 'Country',
    w          => 200,
    options    => ['US', 'UK', 'Canada'],
), 'PDF::Make::Builder', 'combo field');

# ── Listbox ──────────────────────────────────────────────

isa_ok($b->add_field(
    type       => 'listbox',
    name       => 'langs',
    label      => 'Languages',
    w          => 200,
    h          => 80,
    options    => ['Perl', 'Python', 'Ruby', 'Go', 'Rust'],
), 'PDF::Make::Builder', 'listbox field');

# ── Button with URL action ───────────────────────────────

isa_ok($b->add_field(
    type       => 'button',
    name       => 'visit',
    caption    => 'Visit CPAN',
    url        => 'https://metacpan.org',
    w          => 120,
), 'PDF::Make::Builder', 'button with URL');

# ── Button with reset action ────────────────────────────

isa_ok($b->add_field(
    type       => 'button',
    name       => 'reset_btn',
    caption    => 'Reset',
    is_reset   => 1,
    w          => 100,
), 'PDF::Make::Builder', 'reset button');

# ── Required field ───────────────────────────────────────

isa_ok($b->add_field(
    type       => 'text',
    name       => 'required_field',
    label      => 'Required',
    required   => 1,
    w          => 200,
), 'PDF::Make::Builder', 'required field');

# ── Readonly field ───────────────────────────────────────

isa_ok($b->add_field(
    type          => 'text',
    name          => 'readonly_field',
    label         => 'Read Only',
    readonly      => 1,
    default_value => 'Cannot edit',
    w             => 200,
), 'PDF::Make::Builder', 'readonly field');

# ── Custom styling ───────────────────────────────────────

isa_ok($b->add_field(
    type          => 'text',
    name          => 'styled',
    label         => 'Styled Field',
    w             => 250,
    border_colour => '#3498db',
    bg_colour     => '#ecf0f1',
    label_colour  => '#2c3e50',
    label_size    => 11,
    font_size     => 12,
), 'PDF::Make::Builder', 'styled field');

# ── Save and verify PDF structure (before flatten) ───────

$b->save;
ok(-f $tmpfile, 'form PDF created');
ok(-s $tmpfile > 1000, 'form PDF has substantial size');

open my $fh, '<:raw', $tmpfile;
my $bytes = do { local $/; <$fh> };

like($bytes, qr/%PDF/, 'valid PDF header');
like($bytes, qr/%%EOF/, 'valid PDF trailer');
like($bytes, qr/AcroForm/, 'PDF has /AcroForm');

# Field names in output
for my $name (qw(name email bio agree country langs visit reset_btn required_field)) {
    like($bytes, qr/$name/, "field '$name' present in PDF");
}

# Widget annotations
my $widget_count = () = $bytes =~ m{/Widget}g;
ok($widget_count >= 10, "has $widget_count widget annotations (>= 10)");

# Button actions
like($bytes, qr/URI.*metacpan/, 'button has URI action');
like($bytes, qr/ResetForm/, 'reset button has ResetForm action');

# ── flatten_form ─────────────────────────────────────────

my $tmpflat = File::Temp::tmpnam() . '.pdf';
END { unlink $tmpflat if $tmpflat && -f $tmpflat }
my $b2 = PDF::Make::Builder->new(file_name => $tmpflat);
$b2->add_page(page_size => 'Letter');
$b2->add_field(type => 'text', name => 'flat_field',
               rect => [72, 700, 300, 720], default => 'Flattened');
isa_ok($b2->flatten_form, 'PDF::Make::Builder', 'flatten_form returns self');
$b2->save;
ok(-f $tmpflat, 'flattened PDF created');
open my $fh2, '<:raw', $tmpflat;
my $flat_bytes = do { local $/; <$fh2> };
ok($flat_bytes !~ /AcroForm/, 'flattened PDF has no AcroForm');

done_testing;
