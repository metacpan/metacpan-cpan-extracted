package PDF::Make::Markup::Diff;
use strict;
use warnings;

use File::Temp ();
use PDF::Make ();
use PDF::Make::Builder ();
use PDF::Make::Parser ();
use PDF::Make::Reader ();

our $VERSION = '0.11';

# Which pages changed between two renders, and what text moved - the
# question an engine version bump has to answer for every pinned
# template before anyone opts in, and the question this dist's own CI
# asks of the corpus on every commit to the layout code. In the dist
# because the dist's CI is its first caller; the service's upgrade
# review is the second.
#
# The unit is the positioned word: structured extraction gives every
# word with its coordinates, rounded to the point, so antialias-scale
# noise cannot flag a page while a moved column can. A pixel mode
# arrives with the rasterizer; the contract here does not change.
#
# What DID change in this release is the reporting. Until now a page was a
# bag of "text@x,y" counts and the report was the bag difference, sorted
# by that key. Two things came out of that, and both were wrong for the
# only reader this exists for - a person deciding whether to publish:
#
#   * Editing one word moves every word after it on the line, so all of
#     them differ by coordinate and all of them are reported. Changing
#     "may" to "we" reported five removed words and five added ones.
#   * Sorting by the key sorts by the text, so the report arrived in
#     alphabetical order: "Aug change separately. ust we". Prose, in the
#     wrong order, is not readable as prose - it reads as corruption.
#
# So the words are kept in reading order and aligned with a longest
# common subsequence over the TEXT. What is reported is what a proof
# reader would mark: the words that are actually gone, the words that
# are actually new, in the order they are read. Movement is reported
# only when nothing textual changed, because that is the only time it is
# the news rather than the consequence of the news - a page that reflowed
# under a new engine with every word intact is exactly what the upgrade
# review exists to catch.

# pages($bytes): per-page words in reading order,
#   [ [ { text => $s, x => $int, y => $int }, ... ], ... ]
#
# Reading order is imposed here rather than taken from the extractor:
# lines top to bottom (PDF y grows upward, so descending), words left to
# right. A re-encode that hands back the same page in a different block
# order must not read as a change.
sub pages {
    my ($class, $bytes) = @_;
    my ($fh, $tmp) = File::Temp::tempfile(SUFFIX => '.pdf', UNLINK => 1);
    binmode $fh;
    print {$fh} $bytes;
    close $fh or die "PDF::Make::Markup::Diff: scratch write failed: $!";

    my $parser = PDF::Make::Parser->from_bytes($bytes);
    $parser->parse;
    my $count = PDF::Make::Reader->new($parser)->page_count;

    # Not $b: the sort below wants its own, and a lexical $b in scope
    # shadows the one sort sets.
    my $builder = PDF::Make::Builder->new(file_name => 'unsaved');
    my @pages;
    for my $page (0 .. $count - 1) {
        my $result
            = eval { $builder->extract_structured($tmp, page => $page) };
        my @words;
        if ($result) {
            for my $block ($result->blocks) {
                for my $line ($block->lines) {
                    for my $word ($line->words) {
                        # x1 and size are working state for the glue
                        # below and are dropped before this is returned;
                        # x and y stay rounded to the point, so
                        # sub-point noise cannot flag a page.
                        push @words, {
                            text => $word->text,
                            x    => int($word->x0 + 0.5),
                            y    => int($word->y0 + 0.5),
                            x0   => $word->x0,
                            x1   => $word->x1,
                            size => $word->font_size,
                        };
                    }
                }
            }
        }
        push @pages, _coalesce([
            sort { $b->{y} <=> $a->{y} || $a->{x} <=> $b->{x} } @words
        ]);
    }
    unlink $tmp;
    return \@pages;
}

# Structured extraction reports a word per text run, and a run ends
# wherever the writer happened to end one - a kerning pair, a font
# switch, the encoder's own buffering. Two renders of nearly the same
# page therefore chop the same line into different pieces: one gives
# "rate." and the other "rate" then ".", one gives "Aug" "ust" and the
# other "Au" "gust". Nothing moved and nothing was edited, but a
# comparison of the pieces reports four changes.
#
# So pieces are glued back into words here, before anything is compared.
# Two pieces on one line with no gap between them were never two words:
# there is no space on the page between them, and a reader reading the
# page aloud would not pause. The threshold is a fraction of the type
# size rather than a fixed number of points, because the gap that means
# "space" scales with the type - and it is well under a real space
# (0.278em in Helvetica) so that words genuinely set apart stay apart.
my $JOIN_EM = 0.15;

sub _coalesce {
    my ($words) = @_;
    my @out;
    for my $w (@$words) {
        my $prev = @out ? $out[-1] : undef;
        if ($prev && $prev->{y} == $w->{y}) {
            # The gap is measured unrounded: x and y are rounded to the
            # point for comparison, and a half-point of rounding either
            # way is a large fraction of the threshold.
            my $em  = $w->{size} || $prev->{size} || 0;
            my $gap = $w->{x0} - $prev->{x1};
            if ($gap <= $em * $JOIN_EM) {
                $prev->{text} .= $w->{text};
                $prev->{x1} = $w->{x1} > $prev->{x1} ? $w->{x1} : $prev->{x1};
                next;
            }
        }
        push @out, { %$w };
    }
    delete @{$_}{qw(x0 x1 size)} for @out;
    return \@out;
}

# diff($bytes_a, $bytes_b): { pages_a, pages_b, changed,
#   pages => [ { page, changed, removed => [...], added => [...],
#                moved => [...] } ] }
sub diff {
    my ($class, $bytes_a, $bytes_b) = @_;
    my $a = $class->pages($bytes_a);
    my $b = $class->pages($bytes_b);

    my $n = @$a > @$b ? @$a : @$b;
    my @pages;
    for my $i (0 .. $n - 1) {
        my $wa = $a->[$i] || [];
        my $wb = $b->[$i] || [];
        my ($removed, $added, $moved) = _compare($wa, $wb);
        push @pages, {
            page    => $i + 1,
            changed => (@$removed || @$added || @$moved
                        || $i >= @$a || $i >= @$b) ? 1 : 0,
            removed => $removed,
            added   => $added,
            moved   => $moved,
        };
    }
    return {
        pages_a => scalar @$a,
        pages_b => scalar @$b,
        changed => scalar(grep { $_->{changed} } @pages),
        pages   => \@pages,
    };
}

# The most words either list will report. A page that changed wholesale
# says so with its first few dozen words; printing nine hundred helps
# nobody.
my $CAP = 40;

# _compare(\@a, \@b) -> (\@removed, \@added, \@moved), each a list of
# words in reading order.
sub _compare {
    my ($wa, $wb) = @_;
    my @ta = map { $_->{text} } @$wa;
    my @tb = map { $_->{text} } @$wb;

    my $pairs = _align(\@ta, \@tb);

    my (%kept_a, %kept_b);
    my @moved;
    for my $p (@$pairs) {
        my ($i, $j) = @$p;
        $kept_a{$i} = $kept_b{$j} = 1;
        push @moved, $wa->[$i]{text}
            if $wa->[$i]{x} != $wb->[$j]{x} || $wa->[$i]{y} != $wb->[$j]{y};
    }

    my @removed = map { $ta[$_] } grep { !$kept_a{$_} } 0 .. $#ta;
    my @added   = map { $tb[$_] } grep { !$kept_b{$_} } 0 .. $#tb;

    # Movement is only news when nothing was written or deleted: edit a
    # word and everything after it on the line shifts, and reporting
    # that is how the report became unreadable in the first place. The
    # page is still flagged as changed either way - by the text.
    @moved = () if @removed || @added;

    splice @$_, $CAP for grep { @$_ > $CAP } \@removed, \@added, \@moved;
    return (\@removed, \@added, \@moved);
}

# Longest common subsequence over the two word lists, as [ [ai, bi] ]
# index pairs.
#
# The identical head and tail are stripped first, which is not an
# optimisation so much as the whole algorithm in practice: the two
# renders being compared are almost always the same page with a few
# words touched, so the quadratic middle is a handful of entries. When
# it is not - two genuinely unrelated pages - the fallback is a multiset
# difference, which loses the alignment but keeps reading order and
# cannot take a minute over a dense page.
my $LCS_MAX = 400;

sub _align {
    my ($ta, $tb) = @_;
    my ($na, $nb) = (scalar @$ta, scalar @$tb);

    my $head = 0;
    $head++ while $head < $na && $head < $nb
        && $ta->[$head] eq $tb->[$head];

    my $tail = 0;
    $tail++ while $tail < $na - $head && $tail < $nb - $head
        && $ta->[$na - 1 - $tail] eq $tb->[$nb - 1 - $tail];

    my @pairs = map { [ $_, $_ ] } 0 .. $head - 1;
    push @pairs, [ $na - 1 - $_, $nb - 1 - $_ ] for reverse 0 .. $tail - 1;

    my ($ma, $mb) = ($na - $head - $tail, $nb - $head - $tail);
    return [ sort { $a->[0] <=> $b->[0] } @pairs ] if !$ma || !$mb;

    my @middle = ($ma > $LCS_MAX || $mb > $LCS_MAX)
        ? _greedy_middle($ta, $tb, $head, $ma, $mb)
        : _lcs_middle($ta, $tb, $head, $ma, $mb);

    return [ sort { $a->[0] <=> $b->[0] } @pairs, @middle ];
}

sub _lcs_middle {
    my ($ta, $tb, $head, $ma, $mb) = @_;

    # Row-at-a-time table, walked back through the stored rows.
    my @rows = ([ (0) x ($mb + 1) ]);
    for my $i (1 .. $ma) {
        my $prev = $rows[$i - 1];
        my @row  = (0);
        for my $j (1 .. $mb) {
            $row[$j] = $ta->[$head + $i - 1] eq $tb->[$head + $j - 1]
                ? $prev->[$j - 1] + 1
                : ($prev->[$j] >= $row[$j - 1] ? $prev->[$j] : $row[$j - 1]);
        }
        push @rows, \@row;
    }

    my @pairs;
    my ($i, $j) = ($ma, $mb);
    while ($i > 0 && $j > 0) {
        if ($ta->[$head + $i - 1] eq $tb->[$head + $j - 1]) {
            unshift @pairs, [ $head + $i - 1, $head + $j - 1 ];
            $i--; $j--;
        }
        elsif ($rows[$i - 1][$j] >= $rows[$i][$j - 1]) { $i-- }
        else { $j-- }
    }
    return @pairs;
}

# The fallback for two long, wholly different runs: match each word to
# the next unclaimed occurrence of the same text. Not minimal, but in
# reading order and linear, and it is only reached where the honest
# answer is already "this page was rewritten".
sub _greedy_middle {
    my ($ta, $tb, $head, $ma, $mb) = @_;
    my %next;
    push @{ $next{ $tb->[$head + $_] } }, $head + $_ for 0 .. $mb - 1;
    my @pairs;
    my $floor = $head - 1;
    for my $i (0 .. $ma - 1) {
        my $list = $next{ $ta->[$head + $i] } or next;
        shift @$list while @$list && $list->[0] <= $floor;
        next unless @$list;
        my $j = shift @$list;
        $floor = $j;
        push @pairs, [ $head + $i, $j ];
    }
    return @pairs;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Markup::Diff - which pages changed between two renders

=head1 SYNOPSIS

    my $d = PDF::Make::Markup::Diff->diff($bytes_before, $bytes_after);
    printf "%d of %d pages changed\n", $d->{changed}, $d->{pages_b};
    for my $p (@{ $d->{pages} }) {
        next unless $p->{changed};
        printf "page %d: -%s +%s\n", $p->{page},
            "@{$p->{removed}}", "@{$p->{added}}";
        printf "page %d: %s moved\n", $p->{page}, "@{$p->{moved}}"
            if @{ $p->{moved} };
    }

=head1 DESCRIPTION

The diff behind the engine version promise. A layout change that moves
a corpus page is a deliberate engine version bump or it does not merge
- this dist's own corpus test asks exactly that - and a hosted
template's upgrade review asks it again per fixture before a customer
opts in.

The unit is the positioned word from structured extraction, coordinates
rounded to the point: a moved column flags its page, a re-encoded but
identical page does not, and no rasterizer is required. When the
rasterizer lands a pixel mode joins; this interface stays.

=head1 WHAT IS REPORTED

Words are kept in reading order - lines top to bottom, words left to
right - and the two pages are aligned by a longest common subsequence
over the text. Each page then reports three lists, all in reading order:

=over 4

=item C<removed>

Words present before and gone after.

=item C<added>

Words new after.

=item C<moved>

Words whose text survived but whose position did not - B<and only when
nothing was removed or added>. Editing a word shifts every word after it
on the line, so once the text has changed, movement is the consequence
rather than the news. A page whose every word survived in a new place is
the reflow an engine upgrade has to be checked for, and that is the case
this list exists to name.

=back

C<changed> is true if any of the three is non-empty, so a page that only
reflowed is still flagged. Each list is capped at forty words: a page
that changed wholesale says so with its first few dozen.

=head1 METHODS

=head2 pages

    my $pages = PDF::Make::Markup::Diff->pages($pdf_bytes);

Per-page words in reading order, each C<< { text, x, y } >> with the
coordinates rounded to the point.

Before 0.11 this returned per-page bags of C<"text@x,y"> counts.

=head2 diff

    my $d = PDF::Make::Markup::Diff->diff($bytes_a, $bytes_b);

C<< { pages_a, pages_b, changed, pages => [ { page, changed, removed,
added, moved } ] } >>.

=cut
