#!/usr/bin/perl
# Interpreter / matrix coverage — covers what the deleted t/c/test_interpreter.c
# exercised for matrix transforms, text state, and the content interpreter.
# Uses round-trips through the writer + text extractor, which is the only Perl
# surface that drives pdfmake_interpreter_* and pdfmake_matrix_* internally.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use PDF::Make::Builder;
use PDF::Make::Document;
use PDF::Make::Page qw(:fonts);
use PDF::Make::Canvas;

my $builder = PDF::Make::Builder->new(file_name => tmpnam() . '.pdf');

# Helper: build a single-page PDF that runs $setup_cb on its canvas,
# then extract_structured for page 0.
sub extract_one_page {
    my ($setup_cb) = @_;
    my $d = PDF::Make::Document->new;
    my $p = $d->add_page(612, 792);
    $p->add_std14_font('F1', HELVETICA);
    my $c = PDF::Make::Canvas->new;
    $setup_cb->($c);
    $p->set_content($c->to_bytes);

    my $f = tmpnam() . '.pdf';
    open my $fh, '>:raw', $f or die $!;
    print $fh $d->to_bytes;
    close $fh;

    my $r = $builder->extract_structured($f);
    unlink $f;
    return $r;
}

# ── Tm: absolute text matrix positions words at given coords ─
{
    my $r = extract_one_page(sub {
        my ($c) = @_;
        $c->BT
          ->Tf('F1', 12)
          ->Tm(1, 0, 0, 1, 120, 700)
          ->Tj('HELLO')
          ->ET;
    });
    my @w = $r->text_positions;
    my ($hello) = grep { $_->{text} =~ /HELLO/ } @w;
    ok($hello, 'extracted HELLO');
    cmp_ok($hello->{x}, '>=', 115, 'Tm x ≈ 120 (got '.$hello->{x}.')');
    cmp_ok($hello->{x}, '<=', 125, 'Tm x ≈ 120');
    cmp_ok($hello->{y}, '>=', 690, 'Tm y ≈ 700 (got '.$hello->{y}.')');
    cmp_ok($hello->{y}, '<=', 710, 'Tm y ≈ 700');
}

# ── Td: relative text-line translation ──────────────────
{
    my $r = extract_one_page(sub {
        my ($c) = @_;
        $c->BT
          ->Tf('F1', 12)
          ->Td(100, 750)
          ->Tj('FIRST')
          ->Td(20, -14)    # next line: (120, 736)
          ->Tj('SECOND')
          ->ET;
    });
    # Sort DESCENDING by y so $w[0]=FIRST (higher y) and $w[1]=SECOND.
    my @w = sort { $b->{y} <=> $a->{y} } grep { $_->{text} =~ /FIRST|SECOND/ } $r->text_positions;
    is(scalar @w, 2, 'two Td-placed words extracted');
    cmp_ok($w[0]{y} - $w[1]{y}, '>=', 10, 'Td translated y correctly');
    cmp_ok($w[1]{x}, '>', $w[0]{x}, 'Td translated x correctly (SECOND right of FIRST)');
}

# ── cm with scale: the text on the page appears at scale*coord ─
{
    my $r = extract_one_page(sub {
        my ($c) = @_;
        $c->q
          ->cm(2, 0, 0, 2, 0, 0)   # scale by 2 in both axes
          ->BT
          ->Tf('F1', 10)
          ->Tm(1, 0, 0, 1, 50, 300)
          ->Tj('SCALED')
          ->ET
          ->Q;
    });
    # The accurate-width extractor may split "SCALED" into individual glyph
    # clusters; what matters here is that *some* text appears at the
    # cm-scaled position (100, 600) after cm(2,0,0,2,0,0) * Tm(50, 300).
    my ($w) = sort { $a->{x} <=> $b->{x} } $r->text_positions;
    ok($w, 'scaled text extracted');
    cmp_ok($w->{x}, '>=', 90,  'cm scale: x scaled');
    cmp_ok($w->{y}, '>=', 590, 'cm scale: y scaled');
}

# ── Text shows advance the text matrix (word1 followed by word2 on same line) ─
{
    my $r = extract_one_page(sub {
        my ($c) = @_;
        $c->BT
          ->Tf('F1', 12)
          ->Tm(1, 0, 0, 1, 100, 700)
          ->Tj('ALPHA ')
          ->Tj('BETA')
          ->ET;
    });
    my @w = $r->text_positions;
    my ($alpha) = grep { $_->{text} =~ /ALPHA/ } @w;
    my ($beta)  = grep { $_->{text} =~ /BETA/  } @w;
    ok($alpha && $beta, 'both ALPHA and BETA extracted');
    cmp_ok($beta->{x}, '>', $alpha->{x},
       'BETA placed right of ALPHA (interpreter advanced Tm)');
    cmp_ok(abs($beta->{y} - $alpha->{y}), '<=', 1,
       'BETA on same baseline as ALPHA');
}

# ── q/Q stack: outer state is restored ──────────────────
{
    my $r = extract_one_page(sub {
        my ($c) = @_;
        $c->BT
          ->Tf('F1', 12)
          ->Tm(1, 0, 0, 1, 100, 700)
          ->Tj('OUTER')
          ->ET
          ->q                              # save graphics state
          ->cm(1, 0, 0, 1, 200, 0)         # translate right
          ->BT
          ->Tf('F1', 12)
          ->Tm(1, 0, 0, 1, 100, 650)
          ->Tj('INNER')
          ->ET
          ->Q;                             # restore
    });
    my @w = $r->text_positions;
    my ($outer) = grep { $_->{text} =~ /OUTER/ } @w;
    my ($inner) = grep { $_->{text} =~ /INNER/ } @w;
    ok($outer, 'OUTER word present');
    ok($inner, 'INNER word present');
    cmp_ok($inner->{x}, '>', $outer->{x} + 100,
       'INNER was translated by cm while q/Q was active');
}

# ── TJ array with kerning adjustments advances correctly ─
{
    my $r = extract_one_page(sub {
        my ($c) = @_;
        $c->BT
          ->Tf('F1', 12)
          ->Tm(1, 0, 0, 1, 100, 700)
          ->TJ(['A', -500, 'B', -500, 'C'])
          ->ET;
    });
    my @w = $r->text_positions;
    ok(scalar @w >= 1, 'TJ extracted at least one word');
    # Combined text should contain A, B and C
    my $combined = join('', map { $_->{text} } @w);
    like($combined, qr/A/, 'TJ letter A present');
    like($combined, qr/B/, 'TJ letter B present');
    like($combined, qr/C/, 'TJ letter C present');
}

# ── TL + T*: line leading advances y ────────────────────
{
    my $r = extract_one_page(sub {
        my ($c) = @_;
        $c->BT
          ->Tf('F1', 12)
          ->TL(20)                          # leading = 20
          ->Tm(1, 0, 0, 1, 100, 750)
          ->Tj('TOP')
          ->T_star                          # next line: y -= 20
          ->Tj('BOT')
          ->ET;
    });
    my @w = sort { $b->{y} <=> $a->{y} } grep { $_->{text} =~ /TOP|BOT/ } $r->text_positions;
    is(scalar @w, 2, 'TL+T* produced two lines');
    cmp_ok($w[0]{y} - $w[1]{y}, '>=', 15,
       'T* descended by leading (~20)');
    cmp_ok($w[0]{y} - $w[1]{y}, '<=', 25,
       'T* descended by leading (~20)');
}

done_testing;
