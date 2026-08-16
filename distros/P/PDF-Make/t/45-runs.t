#!perl

# Inline runs.
#
# The load-bearing test here is the first one: for a single run, the new
# breaking engine must choose exactly the same line breaks as the legacy
# single-font path in PDF::Make::Builder::Text. Every document rendered
# before runs existed depends on those breaks, and the whole point of doing
# this change now rather than later is that line breaking must stop moving
# before anyone pins a template to an engine version.

use strict;
use warnings;
use Test::More;
use PDF::Make::Builder;
use PDF::Make::Builder::Font;
use PDF::Make::Builder::Runs;

my $font = PDF::Make::Builder::Font->new(family => 'Helvetica', size => 10);

# The legacy algorithm, lifted verbatim from Builder::Text::add so the
# comparison is against what actually ships rather than a paraphrase.
sub legacy_lines {
    my ($f, $raw, $text_w, $indent_w) = @_;
    $indent_w ||= 0;
    my @words = split /\s+/, $raw;
    return () unless @words;
    my (@lines, $line, $line_w, $first_line);
    $line = ''; $line_w = $indent_w; $first_line = 1;
    for my $word (@words) {
        my $candidate   = $line eq '' ? $word : ($line . ' ' . $word);
        my $candidate_w = $f->measure_text($candidate);
        my $test_w      = $candidate_w + ($first_line ? $indent_w : 0);
        if ($test_w > $text_w && $line ne '') {
            push @lines, $line;
            $first_line = 0;
            $line   = $word;
            $line_w = $f->measure_text($line);
        } else {
            $line   = $candidate;
            $line_w = $test_w;
        }
    }
    push @lines, $line if $line ne '';
    return @lines;
}

sub run_lines {
    my ($f, $raw, $text_w, $indent_w) = @_;
    my $lines = PDF::Make::Builder::Runs->layout(
        runs     => [ { font => $f, text => $raw } ],
        width    => $text_w,
        indent_w => $indent_w || 0,
    );
    return map { join '', map { $_->{text} } @{ $_->{segs} } } @$lines;
}

subtest 'single run breaks exactly where the legacy path breaks' => sub {
    my @texts = (
        'The quick brown fox jumps over the lazy dog',
        'Amount due on this invoice is payable within thirty days of issue, '
          . 'after which interest accrues at the statutory rate.',
        'Supercalifragilisticexpialidocious antidisestablishmentarianism',
        'one',
        '   leading and trailing whitespace   ',
        'a b c d e f g h i j k l m n o p q r s t u v w x y z',
        join(' ', map { "word$_" } 1 .. 120),
    );

    for my $w (60, 97, 120, 200, 313, 500) {
        for my $t (@texts) {
            my @legacy = legacy_lines($font, $t, $w);
            my @runs   = run_lines($font, $t, $w);
            is_deeply \@runs, \@legacy,
                "width $w: " . substr($t, 0, 28) . '...';
        }
    }
};

subtest 'and with an indent on the first line' => sub {
    my $t = 'The quick brown fox jumps over the lazy dog and keeps on going';
    for my $ind (5, 17, 40) {
        for my $w (120, 240) {
            my @legacy = legacy_lines($font, $t, $w, $ind);
            my @runs   = run_lines($font, $t, $w, $ind);
            is_deeply \@runs, \@legacy, "width $w indent $ind";
        }
    }
};

subtest 'runs break across their own boundaries' => sub {
    my $bold = PDF::Make::Builder::Font->new(
        family => 'Helvetica', size => 10, bold => 1);
    my $lines = PDF::Make::Builder::Runs->layout(
        runs => [
            { font => $font, text => 'Amount due:' },
            { font => $bold, text => '1240.00' },
            { font => $font, text => 'by 30 September, or interest applies' },
        ],
        width => 120,
    );
    ok @$lines > 1, 'wrapped onto several lines';

    my $joined = join ' ', map { join '', map { $_->{text} } @{ $_->{segs} } } @$lines;
    like $joined, qr/Amount due: 1240\.00 by 30 September/,
        'words survive the run boundaries in order';

    my $bold_seen = 0;
    for my $l (@$lines) {
        $bold_seen++ for grep { $_->{font} == $bold } @{ $l->{segs} };
    }
    is $bold_seen, 1, 'the bold run stayed one segment';
};

subtest 'a line takes its metrics from the tallest run on it' => sub {
    my $big = PDF::Make::Builder::Font->new(
        family => 'Helvetica', size => 24, line_height => 30);
    my $lines = PDF::Make::Builder::Runs->layout(
        runs => [
            { font => $font, text => 'small' },
            { font => $big,  text => 'BIG' },
        ],
        width => 500,
    );
    is scalar @$lines, 1, 'one line';
    is $lines->[0]{size}, 24, 'baseline set by the largest size';
    is $lines->[0]{lh},   30, 'line height set by the largest line height';
};

subtest 'segment widths sum to the line width' => sub {
    my $bold = PDF::Make::Builder::Font->new(
        family => 'Times', size => 12, bold => 1);
    my $lines = PDF::Make::Builder::Runs->layout(
        runs => [
            { font => $font, text => 'plain text then ' },
            { font => $bold, text => 'bold text' },
        ],
        width => 1000,
    );
    my $sum = 0;
    $sum += $_->{w} for @{ $lines->[0]{segs} };
    ok abs($sum - $lines->[0]{w}) < 1e-9, 'widths are consistent';
};

subtest 'empty and whitespace-only runs are dropped, not rendered' => sub {
    my $lines = PDF::Make::Builder::Runs->layout(
        runs => [
            { font => $font, text => '' },
            { font => $font, text => '   ' },
            { font => $font, text => 'content' },
        ],
        width => 200,
    );
    is scalar @$lines, 1, 'one line';
    is join('', map { $_->{text} } @{ $lines->[0]{segs} }), 'content',
        'only the real content survives';

    my $none = PDF::Make::Builder::Runs->layout(
        runs => [ { font => $font, text => '  ' } ], width => 200);
    is scalar @$none, 0, 'nothing to lay out yields no lines';
};

subtest 'a document renders through the runs path' => sub {
    use File::Temp qw(tempdir);
    my $dir = tempdir(CLEANUP => 1);
    local $ENV{SOURCE_DATE_EPOCH} = 1600000000;

    my $pdf = PDF::Make::Builder->new(file_name => "$dir/runs");
    $pdf->add_page(page_size => 'A4', padding => 36);
    $pdf->add_text(runs => [
        { text => 'Amount due: ' },
        { text => '1,240.00', bold => 1 },
        { text => ' by 30 September.', italic => 1, colour => '#aa0000' },
    ]);
    $pdf->save;
    ok -s "$dir/runs.pdf", 'wrote a file';

    open my $fh, '<:raw', "$dir/runs.pdf" or die $!;
    local $/;
    my $bytes = <$fh>;
    close $fh;
    like $bytes, qr/F_Helvetica_bold/,   'bold variant was registered';
    like $bytes, qr/F_Helvetica_italic/, 'italic variant was registered';
};

done_testing;
