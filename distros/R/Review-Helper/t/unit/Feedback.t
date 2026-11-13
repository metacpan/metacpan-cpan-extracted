# Test origin: AI
use v5.36;
use Test2::V0;

use File::Temp qw/tempdir/;
use Review::Helper::DB;
use Review::Helper::Feedback;

my $CLASS = 'Review::Helper::Feedback';
my $tmp   = tempdir(CLEANUP => 1);

like(dies { $CLASS->new }, qr/'db' is a required attribute/, 'needs a db');

my $db  = Review::Helper::DB->create("$tmp/r.sqlite", source => 'https://example.com/pr/2');
my $dbh = $db->dbh;
my $id  = $db->review->{id};

is(
    $CLASS->new(db => $db)->export,
    {format => 'review-feedback', format_version => 1, review => $id, source => 'https://example.com/pr/2', iteration => undef, base => undef, head => undef, feedback => [], requests => []},
    'empty review',
);

$dbh->do(q{INSERT INTO iteration (number, base, head, pin, created) VALUES (1, 'b1', 'h1', 'r1', 1), (2, 'b2', 'h2', 'r2', 2)});
$dbh->do(q{INSERT INTO feedback (iteration, target, revision, path, section_name, section_package, line, side, body, created, updated, status, response, resolved_in, reviewer)
           VALUES (1, 'line', 'c1', 'lib/Foo.pm', 'bar', 'Foo', 42, 'new', 'Why?', 1, 1, 'addressed', 'Fixed.', 2, 'Ann <ann@example.com>')});
$dbh->do(q{INSERT INTO feedback (iteration, target, body, created, updated, status) VALUES (2, 'review', 'Overall?', 1, 1, 'open')});
$dbh->do(q{INSERT INTO request (iteration, kind, target, revision, path, note, status, created, reviewer) VALUES (1, 'debate', 'file', 'c1', 'lib/Foo.pm', 'Sure?', 'done', 1, 'Bob')});
$dbh->do(q{INSERT INTO request (iteration, kind, target, note, status, created) VALUES (2, 'split', 'review', NULL, 'open', 1)});

my $all = $CLASS->new(db => $db)->export;
is([@$all{qw/iteration base head/}], [2, 'b2', 'h2'], 'latest iteration');
is(
    $all->{feedback},
    [
        {
            id   => 1,      iteration => 1,           target   => 'line',   commit      => 'c1', topic     => undef, path     => 'lib/Foo.pm', section => {name => 'bar', package => 'Foo'}, flag => undef, line => 42, side => 'new',
            body => 'Why?', status    => 'addressed', response => 'Fixed.', resolved_in => 2,    published => undef, reviewer => 'Ann <ann@example.com>',
        },
        {
            id   => 2,          iteration => 2,      target   => 'review', commit      => undef, topic     => undef, path     => undef, section => undef, flag => undef, line => undef, side => undef,
            body => 'Overall?', status    => 'open', response => undef,    resolved_in => undef, published => undef, reviewer => undef,
        },
    ],
    'feedback entries',
);
is(
    $all->{requests},
    [
        {id => 1, iteration => 1, kind => 'debate', target => 'file',   commit => 'c1',  topic => undef, path => 'lib/Foo.pm', section => undef, note => 'Sure?', status => 'done', case_for => undef, case_against => undef, reviewer => 'Bob'},
        {id => 2, iteration => 2, kind => 'split',  target => 'review', commit => undef, topic => undef, path => undef,        section => undef, note => undef,   status => 'open', case_for => undef, case_against => undef, reviewer => undef},
    ],
    'request entries',
);

my $open = $CLASS->new(db => $db)->export(open => 1);
is([map { $_->{id} } @{$open->{feedback}}, @{$open->{requests}}], [2, 2], 'open only');

# Feedback on a flag, or left by a retired one, names the flag's note and
# sentence, both stored with it (a retired flag may have no row left), its
# path, and the flag's lines in the feedback's iteration, to anchor it.
$dbh->do(q{INSERT INTO commit_entry (id, iteration, position, revision, subject, message) VALUES (1, 1, 1, 'c1', 's', 'm'), (2, 2, 1, 'c2', 's', 'm')});
$dbh->do(q{INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, kind, sentence, created) VALUES ('n1', 1, 'lib/Foo.pm', 3, 5, 'yellow', 'note', 'Words.', 1), ('n1', 2, 'lib/Foo.pm', 7, 9, 'yellow', 'note', 'Words.', 1), ('w', 1, 'lib/Foo.pm', NULL, NULL, 'yellow', 'note', 'Whole.', 1)});
$dbh->do(q{INSERT INTO feedback (iteration, target, revision, path, flag, flag_sentence, body, created, updated, status) VALUES (1, 'flag', 'c1', 'lib/Foo.pm', 'n1', 'Words.', 'Really?', 1, 1, 'open'), (1, 'file', 'c1', 'lib/Foo.pm', 'gone', 'Gone words.', 'Hm.', 1, 1, 'open'), (1, 'flag', 'c1', 'lib/Foo.pm', 'w', 'Whole.', 'All?', 1, 1, 'open')});
my @flagged = grep { $_->{id} > 2 } @{$CLASS->new(db => $db)->export->{feedback}};
is(
    [map { [$_->{target}, $_->{flag}] } @flagged],
    [
        ['flag', {note => 'n1',   sentence => 'Words.',      path => 'lib/Foo.pm', lines => [3, 5]}],
        ['file', {note => 'gone', sentence => 'Gone words.', path => 'lib/Foo.pm', lines => undef}],
        ['flag', {note => 'w',    sentence => 'Whole.',      path => 'lib/Foo.pm', lines => undef}],
    ],
    "the flag a feedback item is on: its lines in the feedback's iteration, none for a whole-file flag or one gone",
);

# The publish list: the exact text of each comment, with its location
# prefix, and a line comment's anchor when the line still counts in the same
# file as that side of the request's diff, as the latest iteration knows it.
subtest publish => sub {
    my $db  = Review::Helper::DB->create("$tmp/p.sqlite", source => 'https://example.com/pr/3');
    my $dbh = $db->dbh;
    my ($A, $B, $C, $OLD) = ('a' x 40, 'b' x 40, 'c' x 40, 'd' x 40);

    $dbh->do(q{INSERT INTO iteration (number, base, head, pin, created, squashed) VALUES (1, 'base', ?, 'r1', 1, 0), (2, 'base', ?, 'r2', 2, 0)}, undef, $OLD, $C);
    $dbh->do(q{INSERT INTO commit_entry (id, iteration, position, revision, subject, message) VALUES (1, 1, 1, ?, 's', 'm'), (2, 2, 1, ?, 's', 'm'), (3, 2, 2, ?, 's', 'm'), (4, 2, 3, ?, 's', 'm')}, undef, $OLD, $A, $B, $C);
    my $file = q{INSERT INTO file_change (commit_id, path, old_path, status, kind, size_unit, split_source) VALUES (?, ?, ?, ?, 'perl', 'lines', 'none')};
    $dbh->do($file, undef, @$_) for [2, 'A.pm', undef, 'M'], [2, 'B.pm', undef, 'M'], [2, 'X.pm', undef, 'M'], [3, 'B.pm', undef, 'M'], [4, 'C.pm', 'X.pm', 'R'];
    $dbh->do(q{INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, kind, sentence, created) VALUES ('n1', 2, 'A.pm', 3, 5, 'yellow', 'note', 'S.', 1), ('n2', 2, 'B.pm', 7, 7, 'yellow', 'note', 'S.', 1)});

    my $id = 0;
    my %ids;
    my $add = sub ($name, %fields) {
        $db->add_feedback(iteration => 2, body => 'Body.', created => 1, updated => 1, status => 'open', %fields);
        $ids{$name} = ++$id;
    };
    $add->(line_new        => target => 'line',    revision => $A,   path => 'A.pm', line => 4, side => 'new');
    $add->(line_old        => target => 'line',    revision => $A,   path => 'A.pm', line => 4, side => 'old');
    $add->(line_stale_new  => target => 'line',    revision => $A,   path => 'B.pm', line => 4, side => 'new');
    $add->(line_stale_old  => target => 'line',    revision => $B,   path => 'B.pm', line => 4, side => 'old');
    $add->(line_renamed    => target => 'line',    revision => $A,   path => 'X.pm', line => 4, side => 'new');
    $add->(line_rewritten  => target => 'line',    revision => $OLD, path => 'Z.pm', line => 4, side => 'new', iteration => 1);
    $add->(file            => target => 'file',    revision => $A,   path => 'A.pm');
    $add->(file_section    => target => 'file',    revision => $A,   path => 'A.pm', section_name => 'sub x');
    $add->(file_flag       => target => 'file',    revision => $A,   path => 'A.pm', flag         => 'gone',  flag_sentence   => 'G.');
    $add->(section         => target => 'section', revision => $A,   path => 'A.pm', section_name => 'sub x', section_package => 'A');
    $add->(commit          => target => 'commit',  revision => $A);
    $add->(commit_topic    => target => 'commit',  revision => $A, topic => 'Parsing');
    $add->(commit_flag     => target => 'commit',  revision => $A, flag  => 'gone', flag_sentence => 'G.');
    $add->(review          => target => 'review');
    $add->(review_topic    => target => 'review', revision => $A, topic => 'Parsing');
    $add->(review_no_topic => target => 'review', revision => $A, topic => '');
    $add->(flag_lines      => target => 'flag',   revision => $A, path  => 'A.pm',    flag          => 'n1',    flag_sentence => 'S.');
    $add->(flag_line_stale => target => 'flag',   revision => $A, path  => 'B.pm',    flag          => 'n2',    flag_sentence => 'S.');
    $add->(flag_file       => target => 'flag',   revision => $A, path  => 'A.pm',    flag          => 'whole', flag_sentence => 'S.');
    $add->(flag_commit     => target => 'flag',   revision => $A, flag  => 'whole',   flag_sentence => 'S.');
    $add->(flag_topic      => target => 'flag',   revision => $A, topic => 'Parsing', flag          => 'whole', flag_sentence => 'S.');

    my $publish = $CLASS->new(db => $db)->publish;
    is([@$publish{qw/format format_version review source head/}], ['review-publish', 1, $db->review->{id}, 'https://example.com/pr/3', $C], 'header');
    my %got  = map { ($_->{id} => $_) } @{$publish->{items}};
    my $item = sub ($name) { $got{$ids{$name}} };

    my $general = sub ($prefix) { {id => E, text => "$prefix\n\nBody.", anchor => undef, fallback => undef} };
    my $line    = sub ($prefix, @anchor) {
        my %anchor;
        @anchor{qw/path line side/} = @anchor;
        return {id => E, text => 'Body.', anchor => \%anchor, fallback => "$prefix\n\nBody."};
    };

    is($item->('line_new'),        $line->("`A.pm:4` (commit aaaaaaa)", 'A.pm', 4, 'new'),              'line, new side: anchored, with its fallback');
    is($item->('line_old'),        $line->("`A.pm:4` (old side, commit aaaaaaa)", 'A.pm', 4, 'old'),    'line, old side: anchored, with its fallback');
    is($item->('line_stale_new'),  $general->('`B.pm:4` (commit aaaaaaa)'),                             'new side of a file a later commit changes: a general comment');
    is($item->('line_stale_old'),  $general->('`B.pm:4` (old side, commit bbbbbbb)'),                   'old side of a file an earlier commit changes: a general comment');
    is($item->('line_renamed'),    $general->('`X.pm:4` (commit aaaaaaa)'),                             'a file a later commit renames: a general comment');
    is($item->('line_rewritten'),  $general->('`Z.pm:4` (commit ddddddd)'),                             'a commit the latest iteration lacks: a general comment');
    is($item->('file'),            $general->('`A.pm`'),                                                'file');
    is($item->('file_section'),    $general->('`A.pm`, was on section `sub x`'),                        'file that was on a section');
    is($item->('file_flag'),       $general->('`A.pm`, was on a flag'),                                 'file a retired flag left');
    is($item->('section'),         $general->('`A.pm`, section `sub x`'),                               'section');
    is($item->('commit'),          $general->('commit aaaaaaa'),                                        'commit');
    is($item->('commit_topic'),    $general->('topic `Parsing` (commit aaaaaaa)'),                      'commit in a topic');
    is($item->('commit_flag'),     $general->('commit aaaaaaa, was on a flag'),                         'commit a retired flag left');
    is($item->('review'),          {id => E, text => 'Body.', anchor => undef, fallback => undef},      'whole change: the body alone');
    is($item->('review_topic'),    $general->('was on topic `Parsing`'),                                'whole change, was on a topic');
    is($item->('review_no_topic'), $general->('was on the files not in a topic yet'),                   'whole change, was on the files not in a topic');
    is($item->('flag_lines'),      $line->('`A.pm:3-5` (commit aaaaaaa), on a flag', 'A.pm', 3, 'new'), "flag with lines: anchored on its first line");
    is($item->('flag_line_stale'), $general->('`B.pm:7` (commit aaaaaaa), on a flag'),                  'flag of one line on a file changed later: a general comment');
    is($item->('flag_file'),       $general->('`A.pm`, on a flag'),                                     'flag without lines: whole file');
    is($item->('flag_commit'),     $general->('commit aaaaaaa, on a flag'),                             'flag without a path: whole commit');
    is($item->('flag_topic'),      $general->('topic `Parsing` (commit aaaaaaa), on a flag'),           'whole-commit flag in a topic');

    my $body = "Caf\x{e9} \x{1F600}\n\n```perl\nmy \$x = 1;\n```\n  trailing  \n";
    $db->add_feedback(iteration => 2, target => 'line', revision => $A, path => "\x{e9}.pm", line => 1, side => 'new', body => $body, created => 1, updated => 1, status => 'open');
    is($CLASS->new(db => $db)->publish(++$id)->{items}, [{id => $id, text => $body, anchor => {path => "\x{e9}.pm", line => 1, side => 'new'}, fallback => "`\x{e9}.pm:1` (commit aaaaaaa)\n\n$body"}], 'unicode, multi-line body kept exactly');

    $db->update_feedback($ids{file}, status => 'addressed');
    $db->set_published($ids{commit});
    my @default = map { $_->{id} } @{$CLASS->new(db => $db)->publish->{items}};
    ok(!(grep { $_ == $ids{file} || $_ == $ids{commit} } @default), 'by default, neither closed nor published items');
    is(scalar(@default),                                                                         $id - 2,                    'every other item');
    is([map { $_->{id} } @{$CLASS->new(db => $db)->publish($ids{commit}, $ids{file})->{items}}], [$ids{commit}, $ids{file}], 'items named by id, whatever their state, in the order named');
    like(dies { $CLASS->new(db => $db)->publish(999) }, qr/No such feedback item: 999/, 'unknown id');

    # The old side of a file the commit renamed counts in its old path,
    # which an earlier commit changed.
    $add->(line_renamed_old => target => 'line', revision => $C, path => 'C.pm', line => 4, side => 'old');
    is($CLASS->new(db => $db)->publish($ids{line_renamed_old})->{items}->[0]->{anchor},        undef,        'old side of a file the commit renamed, whose old path an earlier commit changed: no anchor');
    is([map { $_->{id} } @{$CLASS->new(db => $db)->publish($ids{file}, $ids{file})->{items}}], [$ids{file}], 'an id named twice is listed once');

    # With merged-in commits, position order is not ancestry: any other
    # commit changing the file makes the line stale, on either side.
    $dbh->do(q{UPDATE commit_entry SET merge_id = 4 WHERE id = 3});
    is([map { $_->{anchor} } @{$CLASS->new(db => $db)->publish($ids{line_new}, $ids{line_stale_new})->{items}}], [{path => 'A.pm', line => 4, side => 'new'}, undef], 'merged-in commits: a file no other commit changes still fits');
    $add->(line_merged_old => target => 'line', revision => $A, path => 'B.pm', line => 4, side => 'old');
    is($CLASS->new(db => $db)->publish($ids{line_merged_old})->{items}->[0]->{anchor}, undef, 'merged-in commits: a later commit changing the file makes the old side stale too');
    $dbh->do(q{UPDATE commit_entry SET merge_id = NULL WHERE id = 3});

    # A squashed latest iteration: its one entry is its head; an old-side
    # line counts in its base.
    $dbh->do(q{INSERT INTO iteration (number, base, head, pin, created, squashed) VALUES (3, 'base', ?, 'r3', 3, 1)},         undef, $C);
    $dbh->do(q{INSERT INTO commit_entry (id, iteration, position, revision, subject, message) VALUES (5, 3, 1, ?, 's', 'm')}, undef, $C);
    $dbh->do($file,                                                                                                           undef, 5, 'A.pm', undef, 'M');
    $db->add_feedback(iteration => 3, target => 'line', revision => $C, path => 'A.pm', line => 2, side => $_, body => 'Sq.', created => 1, updated => 1, status => 'open') for qw/new old/;
    is([map { $_->{anchor} } @{$CLASS->new(db => $db)->publish($id + 1, $id + 2)->{items}}], [{path => 'A.pm', line => 2, side => 'new'}, {path => 'A.pm', line => 2, side => 'old'}], 'squashed iteration: both sides fit');
    is($CLASS->new(db => $db)->publish($ids{line_new})->{items}->[0]->{anchor},              undef,                                                                                    'a commit the squashed latest iteration does not hold as an entry: no anchor');

    # A later squashed iteration over another base: the old side moved.
    $dbh->do(q{INSERT INTO iteration (number, base, head, pin, created, squashed) VALUES (4, 'base2', ?, 'r4', 4, 1)},        undef, $C);
    $dbh->do(q{INSERT INTO commit_entry (id, iteration, position, revision, subject, message) VALUES (6, 4, 1, ?, 's', 'm')}, undef, $C);
    $dbh->do($file,                                                                                                           undef, 6, 'A.pm', undef, 'M');
    is([map { $_->{anchor} } @{$CLASS->new(db => $db)->publish($id + 1, $id + 2)->{items}}], [{path => 'A.pm', line => 2, side => 'new'}, undef], 'squashed iteration: the old side no longer fits once the base moved');
};

done_testing;
