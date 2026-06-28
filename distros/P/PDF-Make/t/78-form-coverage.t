#!/usr/bin/perl
# Coverage-targeted tests for PDF::Make::Form error paths, defaults, option variants.
use strict;
use warnings;
use Test::More;
use PDF::Make::Document;
use PDF::Make::Form;

# ── Form->new without doc dies ────────────────────────────
eval { PDF::Make::Form->new() };
like($@, qr/document required/, 'Form->new without doc dies');

# ── Helper ────────────────────────────────────────────────
sub make_form {
    my $pdf = PDF::Make::Document->new;
    $pdf->add_page(612, 792);
    return ($pdf, PDF::Make::Form->new($pdf));
}

# ── All add_* methods die without name ────────────────────
{
    my (undef, $f) = make_form();
    eval { $f->add_text_field() };   like($@, qr/name required/, 'text_field needs name');
    eval { $f->add_checkbox() };     like($@, qr/name required/, 'checkbox needs name');
    eval { $f->add_radio_group() };  like($@, qr/name required/, 'radio_group needs name');
    eval { $f->add_choice() };       like($@, qr/name required/, 'choice needs name');
    eval { $f->add_button() };       like($@, qr/name required/, 'button needs name');
    eval { $f->add_signature() };    like($@, qr/name required/, 'signature needs name');
}

# ── add_* methods with only name (all defaults) ───────────
{
    my (undef, $f) = make_form();
    isa_ok($f->add_text_field(name => 't'),  'PDF::Make::Field', 'text default dims');
    isa_ok($f->add_checkbox(name  => 'c'),   'PDF::Make::Field', 'checkbox default dims');
    isa_ok($f->add_choice(name    => 'ch'),  'PDF::Make::Field', 'choice default dims');
    isa_ok($f->add_button(name    => 'btn'), 'PDF::Make::Field', 'button default dims');
    isa_ok($f->add_signature(name => 'sig'), 'PDF::Make::Field', 'signature default dims');
}

# ── add_choice with hashref options missing export ────────
{
    my (undef, $f) = make_form();
    my $field = $f->add_choice(
        name    => 'country',
        options => [
            { display => 'USA' },                     # missing export
            { display => 'UK', export => 'GB' },      # both
            'Plain String',                           # scalar
        ],
    );
    isa_ok($field, 'PDF::Make::Field', 'choice with mixed options');
}

# ── add_button with explicit caption exercises `caption // $name` ──
{
    my (undef, $f) = make_form();
    isa_ok($f->add_button(name => 'submit', caption => 'Send'),
        'PDF::Make::Field', 'button with caption');
}

# ── _configure_field: da option ───────────────────────────
{
    my (undef, $f) = make_form();
    my $field = $f->add_text_field(name => 'withDA', da => '/Helv 12 Tf 0 g');
    isa_ok($field, 'PDF::Make::Field', 'da option accepted');
}

# ── set_need_appearances with truthy and falsy ───────────
{
    my (undef, $f) = make_form();
    isa_ok($f->set_need_appearances(0), 'PDF::Make::Form', 'NA false');
    isa_ok($f->set_need_appearances(1), 'PDF::Make::Form', 'NA true');
}

# ── field_by_name / field_at misses ───────────────────────
{
    my (undef, $f) = make_form();
    $f->add_text_field(name => 'real');
    is($f->field_by_name('ghost'), undef, 'field_by_name miss returns undef');
    is($f->field_at(999),          undef, 'field_at out-of-range undef');
    isa_ok($f->field_by_name('real'), 'PDF::Make::Field', 'field_by_name hit');
    isa_ok($f->field_at(0),           'PDF::Make::Field', 'field_at hit');
}

done_testing;
