# Test origin: AI
use v5.36;
use Test2::V0;

use Review::Helper::Util qw/json_encode/;
use Review::Helper::Diff qw/move_ranges parse_diff count_lines attribute line_owners map_lines section_hunks/;

my $DIFF = <<'EOT';
diff --git a/lib/Foo.pm b/lib/Foo.pm
index 1111111..2222222 100644
--- a/lib/Foo.pm
+++ b/lib/Foo.pm
@@ -1,5 +1,5 @@ package Foo;
 line1
-old2
-old3
+new2
 line4
+new5
 line5
@@ -10 +10,2 @@ sub bar {
-old10
+new11
+new12
\ No newline at end of file
EOT

subtest parse_diff => sub {
    my $diff = parse_diff($DIFF);

    is($diff->{binary}, 0, "text diff");
    is(
        $diff->{hunks},
        [
            {
                old_start => 1, old_count => 5, new_start => 1, new_count => 5,
                lines     => [
                    {type => ' ', text => 'line1', old => 1,     new => 1},
                    {type => '-', text => 'old2',  old => 2,     new => undef},
                    {type => '-', text => 'old3',  old => 3,     new => undef},
                    {type => '+', text => 'new2',  old => undef, new => 2},
                    {type => ' ', text => 'line4', old => 4,     new => 3},
                    {type => '+', text => 'new5',  old => undef, new => 4},
                    {type => ' ', text => 'line5', old => 5,     new => 5},
                ],
            },
            {
                old_start => 10, old_count => 1, new_start => 10, new_count => 2,
                lines     => [
                    {type => '-', text => 'old10', old => 10,    new => undef},
                    {type => '+', text => 'new11', old => undef, new => 10},
                    {type => '+', text => 'new12', old => undef, new => 11},
                ],
            },
        ],
        "hunks and line numbers",
    );

    is(parse_diff("diff --git a/x.png b/x.png\nBinary files a/x.png and b/x.png differ\n"), {binary => 1, hunks => []}, "binary");
    is(parse_diff(''),                                                                      {binary => 0, hunks => []}, "empty diff");

    my $blank = parse_diff("@@ -1,3 +1,3 @@\n a\n\n-b\n+c\n");
    is($blank->{hunks}->[0]->{lines}->[1], {type => ' ', text => '', old => 2, new => 2}, "stripped blank context line");

    my $dashes = parse_diff("@@ -1,2 +1,2 @@\n--- x\n+++ y\n");
    is([map { $_->{type} } @{$dashes->{hunks}->[0]->{lines}}], ['-', '+'], "lines that look like headers inside a hunk are content");

    like(dies { parse_diff("@@ -1 +1 @@\n?x\n") }, qr/Malformed diff/, "bad hunk line");
};

subtest count_lines => sub {
    my $diff = parse_diff($DIFF);
    is(count_lines($diff->{hunks}), {changed => 2, removed => 1, added => 2}, "runs counted by the min rule");
    is(count_lines([]),             {changed => 0, removed => 0, added => 0}, "nothing");
};

subtest attribute => sub {
    my $diff = parse_diff($DIFF);

    my @sections = (
        {name => 'header', ranges => [[1,  1], [5, 9]], doc_ranges => []},
        {name => 'foo',    ranges => [[2,  4]],         doc_ranges => []},
        {name => 'bar',    ranges => [[10, 20]],        doc_ranges => []},
        {name => 'baz',    ranges => [[21, 30]],        doc_ranges => []},
    );

    attribute($diff->{hunks}, \@sections);

    is(
        [map { [$_->@{qw/name added removed changed touched/}] } @sections],
        [
            ['header', 0, 0, 0, 0],
            ['foo',    1, 1, 1, 1],
            ['bar',    1, 0, 1, 1],
            ['baz',    0, 0, 0, 0],
        ],
        "counts and touched per section",
    );
};

subtest doc_ranges_count => sub {
    my $diff     = parse_diff("@@ -1,2 +1,2 @@\n a\n-b\n+c\n");
    my @sections = ({name => 'foo', ranges => [[10, 12]], doc_ranges => [[2, 2]]});
    attribute($diff->{hunks}, \@sections);
    is($sections[0]->{changed}, 1, "doc lines count toward the unit");
};

subtest deleted_sections => sub {
    # Old lines 3-5 were sub gone; new file kept lines 1-2 and 6-7 as 1-4.
    my $diff = parse_diff("@@ -1,7 +1,4 @@\n a\n b\n-sub gone {\n-  1\n-}\n c\n d\n");

    my @sections = (
        {name => 'header', ranges => [[1, 4]], doc_ranges => []},
        {name => 'gone',   ranges => [], doc_ranges => [], old_ranges => [[3, 5]], deleted => 1},
    );

    attribute($diff->{hunks}, \@sections);
    is([map { [$_->@{qw/removed touched/}] } @sections], [[0, 0], [3, 1]], "removed lines go to the deleted section");

    my $owners = line_owners($diff->{hunks}, \@sections);
    is($owners, [[0, 0, 1, 1, 1, 0, 0]], "per-line owners");
};

subtest removal_owners => sub {
    my @sections = (
        {name => 'a', ranges => [[1, 2]], doc_ranges => []},
        {name => 'b', ranges => [[3, 4]], doc_ranges => []},
    );

    my $middle = parse_diff("@@ -1,4 +1,3 @@\n x\n x\n-gone\n x\n");
    is(line_owners($middle->{hunks}, \@sections), [[0, 0, 1, 1]], "removal goes to the next new-side line's section");

    my $at_end = parse_diff("@@ -3,3 +3,2 @@\n x\n x\n-gone\n");
    is(line_owners($at_end->{hunks}, \@sections), [[1, 1, 1]], "removal at end of file goes to the previous line's section");

    my @held = ({%{$sections[0]}, old_ranges => [[1, 3]]}, $sections[1]);
    is(line_owners($middle->{hunks}, \@held), [[0, 0, 0, 1]], "removal goes first to the section whose old ranges held it");

    my $all = parse_diff("@@ -1,2 +0,0 @@\n-x\n-y\n");
    is(line_owners($all->{hunks}, []), [[undef, undef]], "nothing owns lines of a file that is gone");
};

# Docs right above their code (JSDoc): two parts, split where they meet; a
# removed line takes the part of the line after it.
subtest section_hunks => sub {
    my @new      = ('x', '/** doc */', 'function f() {', '  two', '}', 'y');
    my $hunks    = parse_diff("@@ -2,4 +2,4 @@\n /** doc */\n-function f () {\n+function f() {\n-  one\n+  two\n }\n")->{hunks};
    my $sections = [{ranges => [[1, 1], [6, 6]], doc_ranges => []}, {ranges => [[3, 5]], doc_ranges => [[2, 2]]}];

    my $out = section_hunks($hunks, \@new, $sections, 1);
    is(
        [map { [$_->{part}, @{$_}{qw/old_start old_count new_start new_count/}, join(' ' => map { $_->{type} . ($_->{new} // $_->{old}) } @{$_->{lines}})] } @$out],
        [['docs', 2, 1, 2, 1, ' 2'], ['code', 3, 3, 3, 3, '-3 +3 -4 +4  5']],
        'docs, then code; the removed line goes with the code after it',
    );

    my $same = parse_diff("@@ -1,2 +1,2 @@\n-z\n+x\n /** doc */\n")->{hunks};
    is(section_hunks($same, \@new, $sections, 1), [], 'a unit with no changed line has no hunks');
};

subtest json_numbers => sub {
    my $hunks = parse_diff($DIFF)->{hunks};
    unlike(json_encode($hunks), qr/"(?:old_start|old_count|new_start|new_count|old|new)":"/, 'hunk starts, counts and line numbers encode as JSON numbers');

    my @new      = ('x', '/** doc */', 'function f() {', '  two', '}', 'y');
    my $sections = [{ranges => [[1, 1], [6, 6]], doc_ranges => []}, {ranges => [[3, 5]], doc_ranges => [[2, 2]]}];
    my $section  = section_hunks(parse_diff("@@ -2,4 +2,4 @@\n /** doc */\n-function f () {\n+function f() {\n-  one\n+  two\n }\n")->{hunks}, \@new, $sections, 1);
    unlike(json_encode($section), qr/"(?:old_start|old_count|new_start|new_count|old|new)":"/, 'so do a section\'s');
};

subtest map_lines => sub {
    # Two lines added after old line 2, old line 6 changed.
    my $hunks = parse_diff("@@ -1,3 +1,5 @@\n a\n b\n+n1\n+n2\n c\n@@ -5,3 +7,3 @@\n e\n-f\n+F\n g\n")->{hunks};

    is([map_lines($hunks, 1, 2)],  [1, 2],     "lines before any change stay");
    is([map_lines($hunks, 3, 5)],  [5, 7],     "lines after an insertion shift by it");
    is([map_lines($hunks, 4)],     [6, undef], "a single line keeps an undef end");
    is([map_lines($hunks, 9, 10)], [11, 12],   "lines past every hunk shift by all of them");
    is([map_lines($hunks, 5, 7)],  [],         "a changed line in the range");
    is([map_lines($hunks, 2, 3)],  [],         "lines added inside the range");
    is([map_lines([], 4, 6)],      [4, 6],     "no diff, no change");
};

subtest move_ranges => sub {
    # Two lines added after old line 2, old line 6 changed.
    my $hunks = parse_diff("@@ -1,3 +1,5 @@\n a\n b\n+n1\n+n2\n c\n@@ -5,3 +7,3 @@\n e\n-f\n+F\n g\n")->{hunks};

    is([move_ranges($hunks, [[1, 1], [3, 4]])], [[[1, 1], [5, 6]], 0], 'kept lines move with the diff');
    is([move_ranges($hunks, [[2, 3]])],         [[[2, 2], [5, 5]], 1], 'lines added inside a range mark it changed');
    is([move_ranges($hunks, [[5, 7]])],         [[[7, 7], [9, 9]], 1], 'a changed line is left out and marks it changed');
    is([move_ranges($hunks, [])],               [[], 0], 'no ranges');
    is([move_ranges([], [[4, 6]])],             [[[4, 6]], 0], 'no diff');
};

done_testing;
