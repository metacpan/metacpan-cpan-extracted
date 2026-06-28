#!/usr/bin/perl
# Coverage-targeted tests for PDF::Make::Field getters/setters + edge cases.
use strict;
use warnings;
use Test::More;
use PDF::Make::Document;
use PDF::Make::Form;
use PDF::Make::Field;

sub make_field {
    my $pdf  = PDF::Make::Document->new;
    $pdf->add_page(612, 792);
    my $form = PDF::Make::Form->new($pdf);
    return ($pdf, $form, $form->add_text_field(name => 't', x => 10, y => 10));
}

# ── readonly(): falsy value + getter form ────────────────
{
    my (undef, undef, $f) = make_field();
    isa_ok($f->readonly(0), 'PDF::Make::Field', 'readonly(0) returns self');
    isa_ok($f->readonly(1), 'PDF::Make::Field', 'readonly(1) returns self');
    ok(defined $f->readonly(), 'readonly() getter returns defined');
}

# ── required(): falsy value + getter form ────────────────
{
    my (undef, undef, $f) = make_field();
    isa_ok($f->required(0), 'PDF::Make::Field', 'required(0) returns self');
    ok(defined $f->required(), 'required() getter returns defined');
}

# ── noexport / multiline / password falsy ────────────────
{
    my (undef, undef, $f) = make_field();
    isa_ok($f->noexport(0),  'PDF::Make::Field', 'noexport(0)');
    isa_ok($f->multiline(0), 'PDF::Make::Field', 'multiline(0)');
    isa_ok($f->password(0),  'PDF::Make::Field', 'password(0)');
}

# ── add_radio_option requires value ───────────────────────
{
    my (undef, $form) = make_field();
    my $group = $form->add_radio_group(name => 'grp');
    eval { $group->add_radio_option(x => 0, y => 0) };
    like($@, qr/value required/, 'add_radio_option needs value');
}

# ── add_radio_option with defaults (no x/y/w/h) ───────────
{
    my (undef, $form) = make_field();
    my $group = $form->add_radio_group(name => 'grp2');
    isa_ok(
        $group->add_radio_option(value => 'A'),
        'PDF::Make::Field', 'radio option with defaults');
}

# ── value() as getter vs setter + set_value chain ─────────
{
    my (undef, undef, $f) = make_field();
    isa_ok($f->value('hello'), 'PDF::Make::Field', 'value("hello") setter');
    is($f->value(), 'hello', 'value() getter');
    isa_ok($f->set_value('world'), 'PDF::Make::Field', 'set_value returns self');
}

done_testing;
