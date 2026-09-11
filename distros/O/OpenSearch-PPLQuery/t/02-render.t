use v5.36;

use utf8;

use Test::More;

use OpenSearch::PPLQuery ();

# Table alignment is a question of terminal columns, not characters. The
# expected widths below were taken from glibc wcswidth(3), which is the same
# calculation the terminal uses to decide where a line wraps.
for my $case (
    ['ASCII', 'Tokyo', 5],
    ['East Asian wide characters', "\x{6771}\x{4EAC}", 4],
    ['fullwidth forms', "\x{FF21}\x{FF22}", 4],
    ['Hangul syllables', "\x{AC00}\x{AC01}", 4],
    ['a composed accent', "caf\x{E9}", 4],
    ['a decomposed accent', "cafe\x{0301}", 4],
    ['several stacked marks', "a\x{0301}\x{0302}\x{0303}b", 2],
    ['Devanagari spacing marks', "\x{0915}\x{093F}\x{0924}\x{093E}\x{092C}", 5],
    ['a Hebrew point', "\x{05D0}\x{05B7}\x{05D1}", 2],
    ['a Thai tone mark', "\x{0E01}\x{0E48}\x{0E02}", 2],
    ['an Arabic fatha', "\x{0628}\x{064E}\x{062A}", 2],
    ['a zero-width space', "x\x{200B}y", 2],
    ['an emoji', "\x{1F642}x", 3],
) {
    my ($description, $text, $columns) = @$case;
    is(OpenSearch::PPLQuery::display_width($text), $columns, "$description occupies $columns columns");
}

is(
    OpenSearch::PPLQuery::display_width("caf\x{E9}"),
    OpenSearch::PPLQuery::display_width("cafe\x{0301}"),
    'composed and decomposed spellings of the same text measure alike, so neither needs normalizing first',
);

my $document = {
    schema => [{name => 'city', type => 'keyword'}, {name => 'rows', type => 'integer'}],
    datarows => [
        ['Tokyo', 1],
        ["\x{6771}\x{4EAC}", 22],
        ["cafe\x{0301}", 333],
        ["\x{0915}\x{093F}\x{0924}\x{093E}\x{092C}", 4],
        [undef, 5],
    ],
};

my @ruled = grep { /\A[+|]/ } split /\n/, OpenSearch::PPLQuery::render_table($document);
my %rendered_width = map { OpenSearch::PPLQuery::display_width($_) => 1 } @ruled;
is(scalar(keys %rendered_width), 1, 'every rule and row of a table mixing wide, combining, and ASCII text is one width')
    or diag(join "\n", map { OpenSearch::PPLQuery::display_width($_) . ": $_" } @ruled);

my @narrow = grep { /\A[+|]/ } split /\n/, OpenSearch::PPLQuery::render_table($document, max_width => 4);
my %narrow_width = map { OpenSearch::PPLQuery::display_width($_) => 1 } @narrow;
is(scalar(keys %narrow_width), 1, 'truncated cells leave the table one width')
    or diag(join "\n", map { OpenSearch::PPLQuery::display_width($_) . ": $_" } @narrow);

my $split = OpenSearch::PPLQuery::measured_cell("e\x{0301}e\x{0301}e\x{0301}", 2);
is($split->[0], "e\x{0301}\x{2026}", 'truncation cuts between grapheme clusters, keeping a mark with its base character');
is($split->[1], 2, 'a truncated cell reports the columns it occupies');

my $wide = OpenSearch::PPLQuery::measured_cell("\x{6771}\x{4EAC}\x{6771}", 5);
is($wide->[0], "\x{6771}\x{4EAC}\x{2026}", 'a wide-character cell is truncated on a character boundary');
is($wide->[1], 5, 'a truncated wide-character cell fills the limit exactly');

is(OpenSearch::PPLQuery::measured_cell("\x{6771}\x{4EAC}", 1)->[0], "\x{2026}",
    'a limit too small for even one character yields the ellipsis alone');
is_deeply(OpenSearch::PPLQuery::measured_cell(undef, 0), ['NULL', 4], 'an undefined value renders as NULL');
is_deeply(OpenSearch::PPLQuery::measured_cell("a\tb", 0), ['a\\tb', 4], 'a control character is escaped before it is measured');

done_testing();
