# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use Cpanel::JSON::XS();
use File::Temp qw/tempdir/;
use TestRepo qw/make_repo commit_file run_git write_file/;
use TestCLI qw/cli/;
use TestSplit qw/with_first_lines/;
use Review::Helper::DB;
use Review::Helper::Journal;
use Review::Helper::VCS;
use Review::Helper::Util qw/json_encode json_decode now/;

my $JSON = Cpanel::JSON::XS->new->canonical->utf8;
my $tmp  = tempdir(CLEANUP => 1);
my $dir  = make_repo();

my $FOO = <<'EOT';
package Foo;
use v5.36;

sub alpha($x) {
    return $x + 1;
}

sub beta {
    return 2;
}

1;

__END__

=head1 NAME

Foo - Example.

=head2 alpha($x)

Adds one.

=head2 beta

Returns two.

=cut
EOT

my $FOO2 = <<'EOT';
package Foo;
use v5.36;

sub alpha($x) {
    return $x + 2;
}

sub gamma {
    return 3;
}

1;

__END__

=head1 NAME

Foo - Example.

=head2 alpha($x)

Adds two.

=head2 gamma

Returns three.

=cut
EOT

my $JS = <<'EOT';
export function add(a, b) {
    return a + b;
}

const twice = (x) => {
    return x * 2;
};
EOT

my $MD   = "# Guide\n\nIntro.\n\n## Usage\n\nRun it.\n";
my $MD2  = "# Guide\n\nIntro.\n\n## Usage\n\nRun it twice.\n";
my $CSS  = "body {\n    color: black;\n}\n\na {\n    color: blue;\n}\n";
my $CSS2 = "body {\n    color: black;\n}\n\na {\n    color: red;\n}\n";
my $PNG  = "\x89PNG\r\n\x1a\n\0\0\0\rIHDR\0\0\0\1\0\0\0\1\x08\x06\0\0\0\x1f\x15\xc4\x89";
my $TXT  = join '' => map { "line $_\n" } 1 .. 10;

my $base = commit_file($dir, 'Base', 'lib/Foo.pm' => $FOO, 'README.md' => $MD, 'style.scss' => $CSS, 'notes.txt' => $TXT, 'gone.txt' => "bye\n");

my $c1 = commit_file($dir, 'Rework Foo and add util', 'lib/Foo.pm' => $FOO2, 'js/util.js' => $JS, 'README.md' => $MD2);
run_git($dir, qw/mv notes.txt docs-notes.txt/);
my $c2 = commit_file($dir, 'Assets', 'logo.png' => $PNG, 'style.scss' => $CSS2, 'gone.txt' => undef, 'docs-notes.txt' => $TXT . "line 11\n");

# A side branch of two commits, merged with a merge commit.
run_git($dir, qw/checkout -q -b feature/);
my $b1 = commit_file($dir, 'Add Bar',    'lib/Bar.pm' => "package Bar;\n\nsub bar { 1 }\n\n1;\n");
my $b2 = commit_file($dir, 'Change Bar', 'lib/Bar.pm' => "package Bar;\n\nsub bar { 2 }\n\n1;\n");
run_git($dir, qw/checkout -q main/);
run_git($dir, qw/merge -q --no-ff -m/, 'Merge feature', 'feature');
my $merge = run_git($dir, qw/rev-parse HEAD/) =~ s/\n//r;

my ($exit, $out, $err) = cli($dir, qw{note --flag red --kind deviation --path lib/Foo.pm --unit gamma --sentence}, 'Gamma replaces beta.');
my $note1 = $out =~ s/\n//r;
($exit, $out, $err) = cli($dir, qw/note --flag yellow --path style.scss --sentence/, 'Red links.');
my $note2 = $out =~ s/\n//r;
($exit, $out, $err) = cli($dir, qw/note --kind test-revealed --path lib\/Foo.pm --sentence/, 'The tests needed a fresh object per case.');
my $entry = $out =~ s/\n//r;

($exit, $out, $err) = cli($dir, qw/build --base/, $base, '--title', 'Example change');
is([$exit, $err], [0, ''], 'build succeeds quietly') or diag $err;
my $file = $out =~ s/\n//r;
like($file, qr{/\.git/review-helper/main\.sqlite$}, 'default file named after the branch');

my $db   = Review::Helper::DB->open($file);
my $dbh  = $db->dbh;
my $id   = $db->review->{id};
my $repo = Review::Helper::VCS->detect($dir);
is($repo->pins($id), ["refs/review-helper/$id/1"], 'iteration 1 pinned');
is(
    $dbh->selectall_arrayref('SELECT id, iteration, kind, path, sentence FROM journal_entry'),
    [[$entry, 1, 'test-revealed', 'lib/Foo.pm', 'The tests needed a fresh object per case.']],
    'a note without a flag is a journal entry of iteration 1',
);
ok(!grep({ $_->{id} eq "note:$entry" } @{get_sheet()->{items}}),                                                    'with no sheet item');
ok(!grep({ $_->{id} eq $entry } @{Review::Helper::Journal->new(repo => Review::Helper::VCS->detect($dir))->notes}), 'and gone from the journal');

my ($c1_id) = $dbh->selectrow_array('SELECT id FROM commit_entry WHERE revision = ?', undef, $c1);
my $files = {map { ($_->{path} => $_) } @{$dbh->selectall_arrayref(q{SELECT * FROM file_change WHERE path != 'lib/Bar.pm'}, {Slice => {}})}};

subtest merges => sub {
    my %rows     = map { ($_->{revision} => $_) } @{$dbh->selectall_arrayref('SELECT * FROM commit_entry', {Slice => {}})};
    my $merge_id = $rows{$merge}->{id};
    is([map { $rows{$_}->{merge_id} } $c1, $c2, $merge], [undef, undef, undef], 'mainline commits have no merge');
    is([map { $rows{$_}->{merge_id} } $b1, $b2], [$merge_id, $merge_id], 'branch commits point at their merge');
    ok($rows{$c1}->{position} < $rows{$c2}->{position} && $rows{$c2}->{position} < $rows{$merge}->{position}, 'mainline in order');
    ok($rows{$b1}->{position} < $rows{$b2}->{position} && $rows{$b2}->{position} < $rows{$merge}->{position}, 'branch commits before their merge');
    is([sort map { $_->{position} } values %rows],                                                      [1 .. 5], 'every commit once');
    is($dbh->selectrow_array('SELECT COUNT(*) FROM file_change WHERE commit_id = ?', undef, $merge_id), 0,        'a merge has no file changes');
};

is(
    {map { ($_ => [@{$files->{$_}}{qw/status kind size_unit split_source/}]) } keys %$files},
    {
        'lib/Foo.pm'     => [qw/M perl lines none/],
        'js/util.js'     => [qw/A javascript lines none/],
        'README.md'      => [qw/M markdown lines none/],
        'logo.png'       => [qw/A image bytes none/],
        'style.scss'     => [qw/M text lines none/],
        'gone.txt'       => [qw/D text lines none/],
        'docs-notes.txt' => [qw/R text lines none/],
    },
    'file kinds; nothing is split yet',
);
is($files->{'docs-notes.txt'}->{old_path}, 'notes.txt',  'rename keeps the old path');
is($files->{'logo.png'}->{size_after},     length($PNG), 'image sized in bytes');

is($dbh->selectrow_array('SELECT COUNT(*) FROM section'), 0, 'the build makes no sections');

# Feedback and requests come from the page; insert them as it would.
$dbh->do(q{INSERT INTO feedback (iteration, target, revision, path, line, side, body, created, updated, status) VALUES (1, 'line', ?, 'lib/Foo.pm', 5, 'new', 'Why two?', 1, 1, 'open')}, undef, $c1);
$dbh->do(q{INSERT INTO request (iteration, kind, target, revision, path, note, status, created) VALUES (1, 'debate', 'file', ?, 'js/util.js', 'Needed?', 'open', 1)},                     undef, $c1);
$dbh->do(q{INSERT INTO request (iteration, kind, target, revision, path, note, status, created) VALUES (1, 'split', 'file', ?, 'lib/Foo.pm', 'Right?', 'open', 1)},                       undef, $c1);

sub get_sheet(@all) {
    my ($exit, $out, $err) = cli($dir, 'sheet', $file, @all);
    is($exit, 0, 'sheet succeeds') or diag $err;
    return $JSON->decode($out);
}

sub fill_sheet($data) {
    my $path = "$tmp/sheet.json";
    write_file($tmp, 'sheet.json', $JSON->encode($data));
    return cli($dir, 'fill', $file, $path);
}

my $sheet = get_sheet();
is([@$sheet{qw/format format_version review iteration/}], ['review-sheet', 1, $id, 1], 'sheet header');

my %by_type;
push @{$by_type{$_->{type}}} => $_ for @{$sheet->{items}};
is({map { ($_ => scalar @{$by_type{$_}}) } keys %by_type}, hash { field $_ => T() for qw/summary commit order file split note feedback debate guide/; end }, 'every item type present');

my ($requested) = grep { $_->{about}->{request} } @{$by_type{split}};
is($requested->{about}->{path}, 'lib/Foo.pm', 'split request item');
is(
    [sort map { $_->{about}->{path} } grep { !$_->{optional} } @{$by_type{split}}],
    [qw{README.md docs-notes.txt js/util.js lib/Bar.pm lib/Bar.pm lib/Foo.pm style.scss}],
    'every text file with new lines needs a split; the deleted file has none',
);
ok(!exists $by_type{section}, 'no section items before a split');
is(scalar @{$by_type{commit}},                                                                 5,        'a commit item for each commit, merge included');
is(scalar @{$by_type{order}},                                                                  4,        'no reading order for the merge');
is([map { $_->{about}->{merge} } grep { $_->{about}->{revision} eq $b1 } @{$by_type{commit}}], [$merge], 'commit about names its merge');

subtest rejected => sub {
    my $bad   = $JSON->decode($JSON->encode($sheet));
    my %items = map { ($_->{id} => $_) } @{$bad->{items}};
    $items{"summary:1"}->{rev}                = 'stale';
    $items{"summary:1"}->{fields}->{what}     = 'x';
    $items{"order:$c1_id"}->{fields}->{paths} = ['lib/Foo.pm'];
    $items{"guide:1"}->{fields}->{steps}      = [{target => {type => 'commit', commit => $c1}, commentary => 'Calls `alpha` via Foo::alpha().'}];
    $items{"commit:$c1_id"}->{fields}         = {what => 'x', why => 'y', how => 'z'};
    push @{$bad->{items}} => {id => 'commit:999', type => 'commit', rev => 'x', fields => {what => 'x'}};

    my ($exit, $out, $err) = fill_sheet($bad);
    is($exit, 1, 'rejected');
    like($err, qr/^summary:1: stale revision/m,                  'stale rev');
    like($err, qr/^order:$c1_id: 'paths' must list every path/m, 'order');
    like($err, qr/^guide:1: step 1: 'commentary' must be read/m, 'code tokens');
    like($err, qr/^commit:999: unknown item/m,                   'unknown id');
    is($dbh->selectrow_array('SELECT what FROM iteration'),                                undef, 'nothing written');
    is($dbh->selectrow_array('SELECT what FROM commit_entry WHERE id = ?', undef, $c1_id), undef, 'not even the valid item');
};

my %SPLITS = (
    'lib/Foo.pm' => [
        {name => 'sub alpha',   package => 'Foo', lines     => [[4,  6]],  doc_lines => [[20, 23]]},
        {name => 'sub gamma',   package => 'Foo', lines     => [[8,  10]], doc_lines => [[24, 28]]},
        {name => 'sub beta',    package => 'Foo', old_lines => [[8,  10], [24, 28]]},
        {name => '=head1 NAME', package => 'Foo', lines     => [[16, 19]]},
        {name => 'header',      package => 'Foo', lines     => [[1,  2]]},
        {name => 'end',         package => 'Foo', lines     => [[12, 14]]},
    ],
    'js/util.js' => [{name => 'function add', lines => [[1, 3]]}, {name => 'const twice', lines => [[5, 7]]}],
    'README.md'  => [{name => '# Guide', lines => [[1, 3]]},      {name => '## Usage', package => '# Guide', lines => [[5, 7]]}],
    'style.scss' => [{name => 'body', lines => [[1, 3]]},         {name => 'a', lines => [[5, 7]]}],
    'lib/Bar.pm' => [{name => 'header', package => 'Bar', lines => [[1, 1]]}, {name => 'sub bar', package => 'Bar', lines => [[3, 3]]}, {name => 'end', package => 'Bar', lines => [[5, 5]]}],
);

my $filler = {
    summary => sub ($i) { {what  => 'Whole change.',                  why => 'Because.', how => 'Carefully.'} },
    commit  => sub ($i) { {what  => "Commit $i->{about}->{subject}.", why => 'Needed.',  how => 'Edits.'} },
    order   => sub ($i) { {paths => [reverse sort @{$i->{about}->{paths}}]} },
    file    => sub ($i) { {what  => "File $i->{about}->{path}.", paradigms => 'OOP'} },
    section => sub ($i) { $i->{about}->{path} eq 'style.scss' ? {} : {what => "Section $i->{about}->{name}."} },
    split   => sub ($i) { {sections => with_first_lines($repo, $db, $i->{about}, $SPLITS{$i->{about}->{path}} // [])} },
    note    => sub ($i) {
        return {commit => $c1, path => 'lib/Foo.pm', lines => [8, 10]} if $i->{about}->{path} eq 'lib/Foo.pm';
        return {commit => $c2, path => undef,        lines => undef};
    },
    flag     => sub ($i) { $i->{about}->{color} eq 'red' ? {decision => 'recolor', color => 'yellow', reason => 'Fixed by gamma.'} : {} },
    feedback => sub ($i) { {status   => 'addressed', response     => 'Fixed in the next iteration.'} },
    debate   => sub ($i) { {case_for => 'It helps.', case_against => 'Nobody calls it.'} },
    guide    => sub ($i) {
        return {
            steps => [
                {target => {type => 'summary'}, commentary => 'This change reworks the Foo module.'},
                {target => {type => 'section', commit => $c1, path => 'lib/Foo.pm', section => {name => 'sub gamma', package => 'Foo'}}, highlight => [{path => 'lib/Foo.pm', side => 'new', lines => [8, 10]}], commentary => 'The gamma sub replaces beta.'},
                {target => {type => 'flag',    flag   => $note1}, commentary => 'This flag explains why.'},
                {target => {type => 'diff',    commit => $c2,    path => 'style.scss',     section => {name => 'a', package => undef}}, commentary => 'Links turn red.'},
                {target => {type => 'view',    commit => $c2,    path => 'docs-notes.txt', lines   => [1, 11]}, highlight => [{path => 'docs-notes.txt', side => 'new', lines => [11, 11]}], commentary => 'The notes moved.'},
                {target => {type => 'view',    commit => $merge, path => 'lib/Bar.pm',     lines   => [1, 5]},  highlight => [{path => 'lib/Bar.pm',     side => 'new', lines => [3,  3]}],  commentary => 'At the head, after the merge.'},
            ],
        };
    },
};

sub fill_all($sheet) {
    for my $item (@{$sheet->{items}}) {
        my $fields = $filler->{$item->{type}}->($item);
        $item->{fields} = {%{$item->{fields}}, %$fields};
    }
    return fill_sheet($sheet);
}

($exit, $out, $err) = fill_all($sheet);
is([$exit, $err], [0, ''], 'filled') or diag $err;
like($out, qr/^filled \d+, remaining (\d+)\n\z/, 'counts printed');
my ($remaining) = $out =~ m/remaining (\d+)/;
ok($remaining > 0, 'the sections of the new splits remain');

$sheet = get_sheet();
is([sort map { $_->{type} } grep { !$_->{optional} } @{$sheet->{items}}], [('section') x $remaining], 'only the sections remain');
is(
    [sort map { "$_->{about}->{path} $_->{about}->{name}" } grep { !$_->{optional} } @{$sheet->{items}}],
    [
        'README.md ## Usage', 'js/util.js const twice', 'js/util.js function add',
        'lib/Bar.pm end',     'lib/Bar.pm header', 'lib/Bar.pm sub bar', 'lib/Bar.pm sub bar', 'lib/Foo.pm sub alpha', 'lib/Foo.pm sub beta', 'lib/Foo.pm sub gamma', 'style.scss a',
    ],
    'the touched sections of each split: a file left whole has none, untouched units are dropped, a deleted unit stays',
);
$filler->{section} = sub ($i) { {what => "Section $i->{about}->{name}."} };
($exit, $out, $err) = fill_all($sheet);
# The notes became flags in the first batch; they need nothing more.
is([$exit, $out, $err],  [0, "filled $remaining, remaining 0\n", ''], 'second batch completes the sheet');
is(get_sheet()->{items}, [],                                          'nothing left');

# The agent recolors a flag from the full sheet.
my $all = get_sheet('--all');
($exit, $out, $err) = fill_all({%$all, items => [grep { $_->{type} eq 'flag' } @{$all->{items}}]});
is([$exit, $err], [0, ''], 'a flag recolored from sheet --all') or diag $err;

subtest written => sub {
    is($dbh->selectall_arrayref(q{SELECT DISTINCT split_source FROM file_change WHERE size_unit = 'lines' AND status != 'D'}), [['agent']], 'every text file split by the agent');
    is(
        $dbh->selectall_arrayref(q{SELECT s.name, s.ranges, s.old_ranges, s.deleted, s.added, s.removed, s.changed FROM section s JOIN file_change f ON f.id = s.file_id WHERE f.path = 'lib/Foo.pm' ORDER BY s.position}),
        [
            ['header',      '[[1,3]]',   '[]',               0, 0, 0, 0],
            ['sub alpha',   '[[4,7]]',   '[]',               0, 0, 0, 2],
            ['sub gamma',   '[[8,11]]',  '[]',               0, 4, 0, 0],
            ['end',         '[[12,15]]', '[]',               0, 0, 0, 0],
            ['=head1 NAME', '[[16,19]]', '[]',               0, 0, 0, 0],
            ['sub beta',    '[]',        '[[8,10],[24,28]]', 1, 0, 4, 0],
        ],
        'counted from the diff: a blank line joins the unit before it, removed lines go to the deleted unit that held them; untouched units kept',
    );
    is(
        $dbh->selectall_arrayref(q{SELECT s.name, s.ranges, s.changed FROM section s JOIN file_change f ON f.id = s.file_id WHERE f.path = 'style.scss'}),
        [['body', '[[1,4]]', 0], ['a', '[[5,7]]', 1]],
        'every agent unit is kept, recounted',
    );
    is($dbh->selectall_arrayref(q{SELECT status FROM request ORDER BY id}), [['done'], ['done']],                      'requests done');
    is($dbh->selectrow_hashref('SELECT status, resolved_in FROM feedback'), {status => 'addressed', resolved_in => 1}, 'feedback addressed');
    is(
        $dbh->selectall_arrayref('SELECT note_id, path, line_start, line_end, kind FROM flag ORDER BY id'),
        bag { item [$note1, 'lib/Foo.pm', 8, 10, 'deviation']; item [$note2, undef, undef, undef, 'other']; end },
        'notes placed as flags',
    );
    is($dbh->selectall_arrayref('SELECT color, color_reason FROM flag ORDER BY color_reason'), [['yellow', undef], ['yellow', 'Fixed by gamma.']], 'flag recolored, with its reason');
    is(Review::Helper::Journal->new(repo => $repo)->notes,                                     [],                                                 'journal emptied');
    is($dbh->selectrow_array('SELECT COUNT(*) FROM guide_step WHERE iteration = 1'),           6,                                                  'guide stored, a view at the merge included');
    is(
        $dbh->selectall_arrayref('SELECT f.path, f.read_position FROM file_change f WHERE commit_id = ? ORDER BY read_position', undef, $c1_id),
        [['lib/Foo.pm', 1], ['js/util.js', 2], ['README.md', 3]],
        'reading order',
    );
};

# A rebase-like rewrite: the first commit is replayed unchanged (same
# change id, new sha); the second changes.
run_git($dir, qw/reset -q --hard/, $base);
my $c1b = commit_file($dir, 'Rework Foo and add util (replayed)', 'lib/Foo.pm' => $FOO2, 'js/util.js' => $JS, 'README.md' => $MD2);
isnt($c1b, $c1, 'new sha');
my $c2b = commit_file($dir, 'Assets, revised', 'logo.png' => $PNG, 'style.scss' => $CSS2, 'gone.txt' => undef, 'notes.txt' => $TXT . "line 11\n");

($exit, $out, $err) = cli($dir, 'iterate', $file);
is([$exit, $out, $err], [0, "2\n", ''], 'iterate prints the new number');
is($repo->pins($id), ["refs/review-helper/$id/1", "refs/review-helper/$id/2"], 'both iterations pinned');

subtest carried => sub {
    my $c1b_row = $dbh->selectrow_hashref('SELECT * FROM commit_entry WHERE revision = ?', undef, $c1b);
    is([@$c1b_row{qw/iteration what order_set/}],                                                                            [2, 'Commit Rework Foo and add util.', 1], 'commit text and order carried by change id');
    is($dbh->selectall_arrayref('SELECT color, color_reason, pending FROM flag WHERE commit_id = ?', undef, $c1b_row->{id}), [['yellow', 'Fixed by gamma.', 0]],        'flag carried with its color; its code is unchanged, so not pending');
    is(
        $dbh->selectall_arrayref(q{SELECT f.split_source, s.name, s.what FROM file_change f JOIN section s ON s.file_id = f.id WHERE f.commit_id = ? AND f.path = 'lib/Foo.pm' ORDER BY s.position}, undef, $c1b_row->{id}),
        [['agent', 'header', undef], ['agent', 'sub alpha', 'Section sub alpha.'], ['agent', 'sub gamma', 'Section sub gamma.'], ['agent', 'end', undef], ['agent', '=head1 NAME', undef], ['agent', 'sub beta', 'Section sub beta.']],
        'the split of an unchanged file comes along with its explanations',
    );

    my $c2b_row = $dbh->selectrow_hashref('SELECT * FROM commit_entry WHERE revision = ?', undef, $c2b);
    is([@$c2b_row{qw/what order_set/}], [undef, 0], 'changed commit starts empty');
    is(
        $dbh->selectrow_hashref(q{SELECT split_source, (SELECT COUNT(*) FROM section WHERE file_id = f.id) AS sections FROM file_change f WHERE commit_id = ? AND path = 'style.scss'}, undef, $c2b_row->{id}),
        {split_source => 'none', sections => 0},
        'a file of a changed commit starts unsplit',
    );

    my $sheet = get_sheet();
    my $types = {};
    $types->{$_->{type}}++ for grep { !$_->{optional} } @{$sheet->{items}};
    is($types->{commit},                                                                     1,                           'only the changed commit needs text');
    is($types->{guide},                                                                      1,                           'each iteration gets its own guide');
    is([sort map { $_->{about}->{path} } grep { $_->{type} eq 'split' } @{$sheet->{items}}], ['notes.txt', 'style.scss'], 'and its files a split');

    my ($split) = grep { $_->{type} eq 'split' && $_->{about}->{path} eq 'style.scss' } @{$sheet->{items}};
    is(
        $split->{about}->{previous},
        {commit => $c2, iteration => 1, path => 'style.scss', sections => [{name => 'body', package => undef, lines => [[1, 4]], doc_lines => []}, {name => 'a', package => undef, lines => [[5, 7]], doc_lines => []}]},
        'the whole split an earlier iteration gave the file, as stored',
    );
    $split->{fields}->{sections} = with_first_lines($repo, $db, $split->{about}, $SPLITS{'style.scss'});
    my ($exit, $out, $err) = fill_sheet({%$sheet, items => [$split]});
    is([$exit, $err], [0, ''], 'split again') or diag $err;
    is(
        $dbh->selectall_arrayref(q{SELECT s.name, s.what FROM section s JOIN file_change f ON f.id = s.file_id WHERE f.commit_id = ? AND f.path = 'style.scss'}, undef, $c2b_row->{id}),
        [['body', undef], ['a', undef]],
        'a re-split file is explained afresh, even a section that reads the same',
    );
};

$dbh->do(q{INSERT INTO feedback (iteration, target, revision, body, created, updated, status) VALUES (2, 'commit', ?, 'More?', 2, 2, 'open')}, undef, $c2b);

subtest feedback_export => sub {
    my ($exit, $out, $err) = cli($dir, 'feedback', $file);
    is($exit, 0, 'feedback succeeds') or diag $err;
    my $all = $JSON->decode($out);
    is([@$all{qw/format format_version review source iteration base head/}], ['review-feedback', 1, $id, undef, 2, $base, $c2b], 'header');
    is(
        $all->{feedback}->[0],
        {
            id   => 1,          iteration => 1,           target   => 'line', commit => $c1, topic => undef, path => 'lib/Foo.pm', section => undef, flag => undef, line => 5, side => 'new',
            body => 'Why two?', status    => 'addressed', response => 'Fixed in the next iteration.', resolved_in => 1, published => undef, reviewer => undef,
        },
        'feedback entry',
    );
    is($all->{requests}->[0], {id => 1, iteration => 1, kind => 'debate', target => 'file', commit => $c1, topic => undef, path => 'js/util.js', section => undef, note => 'Needed?', status => 'done', case_for => 'It helps.', case_against => 'Nobody calls it.', reviewer => undef}, 'request entry');

    ($exit, $out) = cli($dir, 'feedback', $file, '--open');
    my $open = $JSON->decode($out);
    is([map { $_->{body} } @{$open->{feedback}}], ['More?'], 'only open feedback');
    is($open->{requests},                         [],        'no open requests');
};

done_testing;
