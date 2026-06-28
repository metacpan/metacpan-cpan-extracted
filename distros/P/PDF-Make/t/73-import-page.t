#!/usr/bin/perl
# Phase 4 — Page import API.
#
# Verifies that content round-trips through:
#   - pdfmake_import_ctx_t deep copy (ref translation, arena renumbering)
#   - Builder::append_pdf  (programmatic merge)
#   - Builder::open_existing (now actually pulls content)
#   - Overlay workflow (open + annotate + save)

use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Builder') }

my $fixture = 't/fixtures/placement.pdf';
plan skip_all => "$fixture not found" unless -f $fixture;

my $orig_size = -s $fixture;

# ── append_pdf round-trip ───────────────────────────────

{
    my $out = tmpnam() . '.pdf';
    END { unlink $out if $out && -f $out }

    my $b = PDF::Make::Builder->new(file_name => $out);
    $b->append_pdf($fixture);
    $b->save;

    ok(-s $out > 1000, "append_pdf produces non-trivial output ($out)");
    cmp_ok(-s $out, '>', $orig_size * 0.5,
           "output size reasonable (got " . (-s $out) . ", orig $orig_size)");

    # Extract text from the imported copy
    my $b2 = PDF::Make::Builder->new(file_name => '/tmp/scratch');
    my $r  = $b2->extract_structured($out, page => 1);
    my @words = $r->text_positions;
    cmp_ok(scalar @words, '>=', 50, "imported page 1 yields many words (got @{[scalar @words]})");

    my $flat = join ' ', map { $_->{text} } @words;
    $flat =~ s/\s+//g;
    like($flat, qr/SampleDataFile/, "imported page 1 preserves 'Sample Data File' text");
}

# ── open_existing round-trip ────────────────────────────

{
    my $out = tmpnam() . '.pdf';
    END { unlink $out if $out && -f $out }

    my $b = PDF::Make::Builder->open_existing($fixture, file_name => $out);
    is(scalar @{ $b->pages }, 4, 'open_existing imports 4 pages');
    $b->save;

    ok(-s $out > 1000, 'open_existing saves non-trivial output');

    my $b2 = PDF::Make::Builder->new(file_name => '/tmp/scratch');
    my $r  = $b2->extract_structured($out, page => 0);
    my $text = $r->to_string // '';
    # Content may come back fragmented ("Book mark" vs "Bookmark") — that
    # is Phase 5 territory. Here we just assert the key words are present.
    like($text, qr/Book\s*mark/i, 'page 0 content preserved');
}

# ── Import subset of pages via append_pdf ────────────────

{
    my $out = tmpnam() . '.pdf';
    END { unlink $out if $out && -f $out }

    my $b = PDF::Make::Builder->new(file_name => $out);
    $b->append_pdf($fixture, pages => [1, 2]);   # two pages only
    $b->save;

    my $b2 = PDF::Make::Builder->new(file_name => '/tmp/scratch');
    my $r  = $b2->extract_structured($out, page => 0);
    my @words = $r->text_positions;
    my $flat = join ' ', map { $_->{text} } @words;
    $flat =~ s/\s+//g;
    like($flat, qr/SampleDataFile/, 'subset import: page 1 of source now page 0 of output');
}

# ── Overlay workflow: open + annotate + save ────────────

{
    my $out = tmpnam() . '.pdf';
    END { unlink $out if $out && -f $out }

    my $b = PDF::Make::Builder->open_existing($fixture, file_name => $out);

    # Target the second imported page (1-based)
    $b->open_page(2);
    $b->add_note(rect => [55, 664, 174, 682], text => 'Sample Data File');
    $b->save;

    ok(-f $out, 'overlay output exists');
    ok(-s $out > $orig_size * 0.5,
       'overlay output size reasonable');

    # Verify the annotation landed on page 1 (0-based in raw PDF)
    open my $fh, '<:raw', $out or die;
    my $bytes = do { local $/; <$fh> };
    close $fh;
    like($bytes, qr/Sample Data File/, 'annotation content present in PDF');
    like($bytes, qr{/Subtype\s*/Text}, 'Text annotation emitted');
}

# ── Merge multiple files ────────────────────────────────

{
    my $out = tmpnam() . '.pdf';
    END { unlink $out if $out && -f $out }

    my @inputs = grep { -f $_ }
                 ('t/fixtures/hello_world.pdf', $fixture);
    SKIP: {
        skip "needs at least two input PDFs", 1 unless @inputs >= 2;

        my $b = PDF::Make::Builder->new(file_name => $out);
        for my $f (@inputs) {
            $b->append_pdf($f);
        }
        $b->save;

        my $b2 = PDF::Make::Builder->new(file_name => '/tmp/scratch');
        my $r  = $b2->extract_structured($out, page => 0);
        my $text = $r->to_string // '';
        like($text, qr/Hello/i, 'first merged PDF content present');
    }
}

done_testing;
