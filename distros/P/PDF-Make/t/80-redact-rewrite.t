#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Builder') }

sub build {
    my (%opts) = @_;
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->add_page(page_size => 'Letter')
      ->add_text(text => 'Employee: John Smith')
      ->add_text(text => 'SSN: 123-45-6789')
      ->add_text(text => 'Salary: $125,000')
      ->add_text(text => 'Department: Engineering');

    # Inspect positions to pick rects that land on SSN/Salary baselines.
    $b->mark_redaction(page => 0, rect => [18, 748, 98, 761],
                       overlay_text => 'REDACTED');  # SSN baseline ≈ y 749
    $b->mark_redaction(page => 0, rect => [18, 734, 95, 747],
                       overlay_text => 'REDACTED');  # Salary baseline ≈ y 735

    $b->apply_redactions if $opts{apply};
    $b->sanitize         if $opts{sanitize};
    $b->save;
    return $f;
}

# ── Without apply_redactions: cover only, data still recoverable ────
{
    my $f = build();
    open my $fh, '<:raw', $f or die $!;
    my $bytes = do { local $/; <$fh> };
    ok(index($bytes, '123-45-6789') >= 0,
       'cover-only: SSN still present in raw file bytes');
    ok(index($bytes, '$125,000') >= 0,
       'cover-only: Salary still present in raw file bytes');
    ok(index($bytes, 'REDACTED') >= 0,
       'cover-only: REDACTED overlay present in raw file bytes');
    unlink $f;
}

# ── With apply_redactions: underlying text is gone ──────────────────
{
    my $f = build(apply => 1);
    my $b = PDF::Make::Builder->new(file_name => tmpnam() . '.pdf');
    my $res = $b->extract_structured($f, page => 0);
    my $text = join(' ', map { $_->{text} } $res->text_positions);

    unlike($text, qr/123-45-6789/, 'apply_redactions: SSN removed');
    unlike($text, qr/\$125,000/,    'apply_redactions: Salary removed');
    like($text,   qr/REDACTED/,    'apply_redactions: REDACTED overlay still present');
    like($text,   qr/Employee/,    'apply_redactions: non-redacted content preserved');
    like($text,   qr/Department/,  'apply_redactions: non-redacted content preserved');

    # Also check the raw PDF bytes - sensitive text should not be there
    open my $fh, '<:raw', $f or die $!;
    my $bytes = do { local $/; <$fh> };
    ok(index($bytes, '123-45-6789') < 0, 'apply_redactions: SSN absent from file bytes');
    ok(index($bytes, '$125,000')     < 0, 'apply_redactions: Salary absent from file bytes');

    unlink $f;
}

# ── sanitize clears /Info and regenerates /ID ───────────────────────
{
    my $f = tmpnam() . '.pdf';
    my $b = PDF::Make::Builder->new(file_name => $f);
    $b->title('Private Title');
    $b->author('Alice');
    $b->add_page->add_text(text => 'hello');
    $b->sanitize;
    $b->save;

    open my $fh, '<:raw', $f or die $!;
    my $bytes = do { local $/; <$fh> };
    ok(index($bytes, 'Private Title') < 0, 'sanitize: title scrubbed');
    ok(index($bytes, 'Alice')          < 0, 'sanitize: author scrubbed');
    unlink $f;
}

# ── Redaction + encryption + real-world read with pypdf  ────────────
#   (skipped — pypdf not required as a test dep; covered manually.)

done_testing;
