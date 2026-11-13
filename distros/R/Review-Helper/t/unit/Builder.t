# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use Cpanel::JSON::XS();
use TestRepo qw/make_repo commit_file run_git pinned_refs/;
use TestSplit qw/fill_splits/;
use Review::Helper::Builder;
use Review::Helper::DB;
use Review::Helper::Journal;
use Review::Helper::Registry;
use Review::Helper::VCS;
use Review::Helper::Sheet;

my $CLASS = 'Review::Helper::Builder';

my $PM = <<'EOT';
package Foo;
use v5.36;

sub keep {
    1;
}

sub drop {
    return 0;
}

1;
EOT

my $PM2 = <<'EOT';
package Foo;
use v5.36;

sub keep {
    2;
}

sub added {
    3;
}

1;
EOT

sub setup() {
    my $dir  = make_repo();
    my $base = commit_file($dir, 'Base', 'lib/Foo.pm' => $PM, 'a.txt' => "a\n", 'blob.dat' => "x\0y");
    my $one  = commit_file($dir, "Caf\xc3\xa9 change", 'lib/Foo.pm' => $PM2, 'a.txt' => "a\nb\n", 'blob.dat' => "x\0z", 'bad.txt' => "ok\n\xff\xfe\n");
    return ($dir, Review::Helper::VCS->detect($dir), $base, $one);
}

sub rows($db, $sql, @bind) { $db->dbh->selectall_arrayref($sql, {Slice => {}}, @bind) }

# The agent's split of setup()'s Foo.pm after the change: keep, added, and
# drop as a deleted unit, and the lines around them.
my @FOO_UNITS = (
    {name => 'sub keep',  package => 'Foo', lines     => [[4,  6]]},
    {name => 'sub added', package => 'Foo', lines     => [[8,  10]]},
    {name => 'sub drop',  package => 'Foo', old_lines => [[8,  10]]},
    {name => 'header',    package => 'Foo', lines     => [[1,  2]]},
    {name => 'end',       package => 'Foo', lines     => [[12, 12]]},
);

# Units as split_sections takes them, from the sheet's shape.
sub units(@entries) {
    return [map { +{name => $_->{name}, package => $_->{package}, ranges => $_->{lines} // [], doc_ranges => $_->{doc_lines} // [], old_ranges => $_->{old_lines} // []} } @entries];
}

subtest constructor => sub {
    like(dies { $CLASS->new }, qr/'repo' is a required attribute/, 'needs a repo');
};

subtest build => sub {
    my ($dir, $repo, $base, $one) = setup();
    my $builder = $CLASS->new(repo => $repo);

    like(dies { $builder->build },                 qr/Missing required parameter 'base'/, 'base required');
    like(dies { $builder->build(base => 'HEAD') }, qr/No commits in /,                    'empty range');
    ok(!-e $repo->state_dir . '/main.sqlite', 'no file left for an empty range');

    my $file = $builder->build(base => $base, title => 'T', source => 'https://example.com/pr/1');
    is($file, $repo->state_dir . '/main.sqlite', 'default file in the git directory, named after the branch');
    like(dies { $builder->build(base => $base) }, qr/already has a review file/, 'one review per builder');

    my $db = $builder->db;
    is([@{$db->review}{qw/title source state/}], ['T', 'https://example.com/pr/1', 'open'], 'review row');

    my $id = $db->review->{id};
    is(rows($db, 'SELECT number, base, head, pin FROM iteration'),   [{number => 1, base => $base, head => $one, pin => "refs/review-helper/$id/1"}], 'iteration row');
    is($repo->pins($id),                                             ["refs/review-helper/$id/1"],                                                    'pinned');
    is(Review::Helper::Registry->new(repo => $repo)->reviews->{$id}, {path => $file, state => 'open'},                                                'registered');

    my ($commit) = @{rows($db, 'SELECT * FROM commit_entry')};
    like(
        $commit,
        {position => 1, revision => $one, parent => $base, subject => "Caf\x{e9} change", message => "Caf\x{e9} change\n", change_id => match(qr/^[0-9a-f]{40}$/), order_set => 0},
        'commit row',
    );

    my %files = map { ($_->{path} => $_) } @{rows($db, 'SELECT * FROM file_change')};
    like($files{'lib/Foo.pm'}, {status => 'M', kind => 'perl', size_unit => 'lines', size_before => 12, size_after => 12, split_source => 'none', added => 0, removed => 0, changed => 3}, 'perl file');
    like($files{'a.txt'},      {kind => 'text', size_unit => 'lines', split_source => 'none', added => 1},                                                                                 'text file');
    like($files{'blob.dat'},   {kind => 'binary', size_unit => 'bytes', size_before => 3, size_after => 3, added => 0},                                                                    'binary file');
    like($files{'bad.txt'},    {status => 'A', kind => 'text', size_before => undef, size_after => 2},                                                                                     'added file with malformed UTF-8');

    is(rows($db, 'SELECT name FROM section'), [], 'nothing is split: every file starts with no sections');
};

subtest split_sections => sub {
    my ($dir, $repo, $base, $one) = setup();
    my $builder = $CLASS->new(repo => $repo);
    my $texts   = $builder->file_texts($one, $base, {path => 'lib/Foo.pm', status => 'M'}, 0);

    my $units = units(@FOO_UNITS);
    is(
        [map { [@$_{qw/name package ranges doc_ranges old_ranges deleted added removed changed/}] } @{$builder->split_sections($texts, $units)}],
        [
            ['header',    'Foo', [[1,  3]],  [], [], 0, 0, 0, 0],
            ['sub keep',  'Foo', [[4,  7]],  [], [], 0, 0, 0, 1],
            ['sub added', 'Foo', [[8,  11]], [], [], 0, 2, 0, 0],
            ['end',       'Foo', [[12, 12]], [], [], 0, 0, 0, 0],
            ['sub drop',  'Foo', [], [], [[8, 10]], 1, 0, 2, 0],
        ],
        'every unit, untouched ones with no counts; a blank line joining the unit before it; the unit with only old lines a deleted section that owns them',
    );
    is($units->[0]->{ranges}, [[4, 6]], 'the units given are not changed');

    is(
        [map { [@$_{qw/name ranges added removed changed/}] } @{$builder->split_sections($texts, units(@FOO_UNITS[0, 1, 3, 4]))}],
        [['header', [[1, 3]], 0, 0, 0], ['sub keep', [[4, 7]], 0, 0, 1], ['sub added', [[8, 11]], 0, 0, 2], ['end', [[12, 12]], 0, 0, 0]],
        'with no deleted unit, removed lines go to the section holding the next line of their hunk',
    );
    is(
        $builder->split_sections($texts, []),
        [],
        'no units: the file is left whole, with no sections',
    );
};

subtest removed_lines_old_side => sub {
    my $dir  = make_repo();
    my $md   = "# A\n\nFirst.\n\nTrailing.\n\n# B\n\nSecond.\n";
    my $base = commit_file($dir, 'Base', 'doc.md' => $md);
    my $one  = commit_file($dir, 'Trim', 'doc.md' => $md =~ s/Trailing\.\n\n//r);
    my $repo = Review::Helper::VCS->detect($dir);
    my $db   = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(base => $base));

    my $touched = sub (@sections) {
        fill_splits($repo, $db, sub ($about) { [@sections] }, all => 1);
        [map { [@$_{qw/name removed/}] } @{rows($db, 'SELECT name, removed FROM section WHERE removed > 0 ORDER BY position')}];
    };
    my $b = {name => '# B', lines => [[5, 7]]};
    is($touched->({name => '# A', lines => [[1, 4]]}, $b), [['# B', 2]], 'a removed trailing paragraph goes to the next section by default');
    is($touched->({name => '# A', lines => [[1, 4]], old_lines => [[1, 6]]}, $b), [['# A', 2]], 'old lines on a live section claim it');
};

subtest names_and_location => sub {
    my ($dir, $repo, $base, $one) = setup();
    my $hd = $repo->state_dir;

    is($CLASS->new(repo => $repo)->build(base => $base), "$hd/main.sqlite",   'named after the branch');
    is($CLASS->new(repo => $repo)->build(base => $base), "$hd/main-2.sqlite", 'a number added when taken');

    run_git($dir, qw{branch feature/x});
    is($CLASS->new(repo => $repo)->build(base => $base, head => 'feature/x'), "$hd/feature-x.sqlite",                   'slashes become dashes');
    is($CLASS->new(repo => $repo)->build(base => $base, head => $one),        "$hd/" . substr($one, 0, 12) . '.sqlite', 'a sha gives its short form');

    run_git($dir, qw/checkout -q --detach/);
    is($CLASS->new(repo => $repo)->build(base => $base), "$hd/" . substr($one, 0, 12) . '.sqlite' =~ s/\.sqlite$/-2.sqlite/r, 'detached HEAD uses the short revision id');
    run_git($dir, qw/checkout -q main/);

    my $warnings = warnings { $CLASS->new(repo => $repo)->build(base => $base, file => "$dir/review.sqlite") };
    is($warnings, [], 'a file in the worktree is accepted quietly');

    like(dies { $CLASS->new(repo => $repo)->build(base => $base, file => '/nonexistent-dir/x.sqlite') }, qr/is not inside the worktree/, 'outside the worktree');
};

subtest failure_removes_file => sub {
    my ($dir, $repo, $base) = setup();
    my $mock = mock $CLASS => (override => [store => sub { die "store failed\n" }]);
    my $file = "$dir/.git/review-helper/fail.sqlite";
    like(dies { $CLASS->new(repo => $repo)->build(base => $base, file => $file) }, qr/^store failed$/, 'error rethrown');
    ok(!-e $file, 'file removed');

    my $bad = "$dir/.git/review-helper/caf\xe9.sqlite";    # Latin-1 byte, not UTF-8
    like(dies { $CLASS->new(repo => $repo)->build(base => $base, file => $bad) }, qr/is not valid UTF-8/, 'a path that is not UTF-8 is refused');
    ok(!-e $bad, 'before any file is written');
    is(pinned_refs($repo->root), [], 'and before any ref is pinned');
};

subtest iterate => sub {
    my ($dir, $repo, $base, $one) = setup();
    my $file = $CLASS->new(repo => $repo)->build(base => $base);
    my $db   = Review::Helper::DB->open($file);
    my $dbh  = $db->dbh;

    like(dies { $CLASS->new(repo => $repo)->iterate }, qr/'db' is required/, 'needs a db');

    my ($commit_id) = $dbh->selectrow_array('SELECT id FROM commit_entry');
    my %file_ids = map { @$_ } @{$dbh->selectall_arrayref('SELECT path, id FROM file_change')};
    fill_splits($repo, $db, sub ($about) { $about->{path} eq 'lib/Foo.pm' ? [@FOO_UNITS] : $about->{path} eq 'a.txt' ? [{name => 'first', lines => [[1, 1]]}, {name => 'second', lines => [[2, 2]]}] : undef });
    $dbh->do(q{UPDATE commit_entry SET what = 'W', why = 'Y', how = 'H', order_set = 1});
    $dbh->do(q{UPDATE file_change SET what = 'F ' || path, read_position = id});
    $dbh->do(q{UPDATE section SET what = 'S ' || name});
    $dbh->do(q{INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, color_reason, kind, sentence, detail, created) VALUES ('n1', ?, 'a.txt', 1, 1, 'yellow', 'Fixed.', 'note', 'S.', 'D.', 5)}, undef, $commit_id);

    # Replay the commit (same change id) and add one that changes Foo again.
    run_git($dir, qw/reset -q --hard/, $base);
    my $replay = commit_file($dir, 'Replayed', 'lib/Foo.pm' => $PM2, 'a.txt' => "a\nb\n", 'blob.dat' => "x\0z", 'bad.txt' => "ok\n\xff\xfe\n");
    my $more   = commit_file($dir, 'More',     'lib/Foo.pm' => $PM2 =~ s/    3;/    4;/r);

    is($CLASS->new(repo => $repo, db => $db)->iterate,                               2,                              'iteration 2');
    is($dbh->selectrow_hashref('SELECT base, head FROM iteration WHERE number = 2'), {base => $base, head => $more}, 'base defaults to the previous one, head to HEAD');

    my $rows = rows($db, 'SELECT * FROM commit_entry WHERE iteration = 2 ORDER BY position');
    like($rows->[0], {revision => $replay, what => 'W', why => 'Y', how => 'H', order_set => 1}, 'replayed commit carries its text and order');
    like($rows->[1], {revision => $more, what => undef, order_set => 0}, 'new commit starts empty');

    my %files = map { ($_->{path} => $_) } @{rows($db, 'SELECT * FROM file_change WHERE commit_id = ?', $rows->[0]->{id})};
    like($files{'lib/Foo.pm'}, {what         => 'F lib/Foo.pm', read_position => $file_ids{'lib/Foo.pm'}, split_source => 'agent'}, 'file text, reading order and split label carried');
    like($files{'bad.txt'},    {split_source => 'none'},                                                                            'a file never split stays unsplit');
    is(
        rows($db, 'SELECT name, ranges, added, what FROM section WHERE file_id = ? ORDER BY position', $files{'a.txt'}->{id}),
        [{name => 'first', ranges => '[[1,1]]', added => 0, what => 'S first'}, {name => 'second', ranges => '[[2,2]]', added => 1, what => 'S second'}],
        'agent split sections carried, untouched ones too',
    );

    is(
        rows($db, 'SELECT note_id, path, line_start, color, color_reason, kind, sentence, detail, created, pending FROM flag WHERE commit_id = ?', $rows->[0]->{id}),
        [{note_id => 'n1', path => 'a.txt', line_start => 1, color => 'yellow', color_reason => 'Fixed.', kind => 'note', sentence => 'S.', detail => 'D.', created => 5, pending => 0}],
        'flags copied to the replayed commit, with their color',
    );
    is(
        $dbh->selectall_arrayref('SELECT name, what FROM section WHERE file_id = ? ORDER BY position', undef, $files{'lib/Foo.pm'}->{id}),
        [['header', 'S header'], ['sub keep', 'S sub keep'], ['sub added', 'S sub added'], ['end', 'S end'], ['sub drop', 'S sub drop']],
        'section text carried',
    );

    my ($more_foo) = $dbh->selectrow_array(q{SELECT id FROM file_change WHERE commit_id = ? AND path = 'lib/Foo.pm'}, undef, $rows->[1]->{id});
    is(
        $dbh->selectrow_hashref('SELECT split_source, (SELECT COUNT(*) FROM section WHERE file_id = ?) AS sections FROM file_change WHERE id = ?', undef, $more_foo, $more_foo),
        {split_source => 'none', sections => 0},
        'a file changed by a new commit starts unsplit',
    );

    is($CLASS->new(repo => $repo, db => $db)->iterate(base => $replay, head => $more), 3, 'explicit range');
    is($dbh->selectrow_array('SELECT COUNT(*) FROM commit_entry WHERE iteration = 3'), 1, 'one commit in it');
    is(scalar @{pinned_refs($repo->root)},                                             3, 'every iteration pinned');
};

subtest rewritten_commit_flags => sub {
    my $dir   = make_repo();
    my $base  = commit_file($dir, 'Base',            'a.txt' => "a\n",              'gone.txt' => "g\n");
    my $first = commit_file($dir, 'Edit a and gone', 'a.txt' => "a1\na2\na3\na4\n", 'gone.txt' => "g1\ng2\n");
    my $repo  = Review::Helper::VCS->detect($dir);
    my $file  = $CLASS->new(repo => $repo)->build(base => $base);
    my $db    = Review::Helper::DB->open($file);
    my $dbh   = $db->dbh;

    my ($old_id) = $dbh->selectrow_array('SELECT id FROM commit_entry');
    my $flag = $dbh->prepare(q{INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, kind, sentence, created) VALUES (?, ?, ?, ?, ?, 'red', 'note', 'S.', 5)});
    $flag->execute('moved', $old_id, 'a.txt',    3,     3);
    $flag->execute('whole', $old_id, 'gone.txt', 1,     2);
    $flag->execute('head',  $old_id, undef,      undef, undef);
    $dbh->do(q{INSERT INTO flag_seen (flag, reviewer, at) SELECT id, 'Ann', 7 FROM flag});

    # Rewrite the commit: a line above the flagged one, gone.txt left as at
    # the base, and a later commit that changes a.txt again.
    run_git($dir, qw/reset -q --hard/, $base);
    my $rewritten = commit_file($dir, 'Edit a',  'a.txt' => "a0\na1\na2\na3\na4\n");
    my $later     = commit_file($dir, 'Touch a', 'a.txt' => "a0\na1\na2\na3\na4\na5\n");
    is($CLASS->new(repo => $repo, db => $db)->iterate, 2, 'iteration 2');

    my %flags = map { ($_->{note_id} => $_) } @{rows($db, q{SELECT f.*, c.revision FROM flag f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = 2})};
    like(
        $flags{moved},
        {revision => $later, path => 'a.txt', line_start => 4, line_end => 4, pending => 1, color => 'red'},
        "a flag of a commit with no partner goes pending on the last commit changing its path, its lines moved",
    );
    like($flags{whole}, {revision => $later, path => 'gone.txt', line_start => undef, pending => 1}, 'with no commit changing its path: the last commit, the whole file');
    like($flags{head}, {revision => $later, path => undef, pending => 1}, 'a whole-commit flag goes on the last commit');
    is($dbh->selectrow_array('SELECT COUNT(*) FROM flag_seen JOIN flag ON flag.id = flag_seen.flag JOIN commit_entry c ON c.id = flag.commit_id WHERE c.iteration = 2'), 0, 'no seen marks follow');
    is($dbh->selectrow_array('SELECT COUNT(*) FROM flag_seen'),                                                                                                          3, 'iteration 1 keeps its marks');

    my %items = map { ($_->{about}->{note} => $_) } grep { $_->{type} eq 'flag' } @{Review::Helper::Sheet->new(repo => $repo, db => $db)->sheet->{items}};
    is([map { [$items{$_}->{about}->{rewritten}, $items{$_}->{about}->{left_change}] } qw/moved whole/], [[T(), F()], [T(), T()]],                             'the sheet says the commit was rewritten, and which file left the change');
    is($items{moved}->{about}->{previous},                                                               {commit => $first, path => 'a.txt', lines => [3, 3]}, 'and where the flag was');
};

# Iteration $number's flags, by note id, with their commit's revision.
sub flags_of($db, $number) {
    return {map { ($_->{note_id} => $_) } @{rows($db, q{SELECT f.*, c.revision FROM flag f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = ?}, $number)}};
}

sub seen_in($db, $number) {
    return $db->dbh->selectrow_array('SELECT COUNT(*) FROM flag_seen JOIN flag ON flag.id = flag_seen.flag JOIN commit_entry c ON c.id = flag.commit_id WHERE c.iteration = ?', undef, $number);
}

subtest rewritten_flags_settle => sub {
    my $dir  = make_repo();
    my $base = commit_file($dir, 'Base',   'a.txt' => "a1\na2\na3\na4\na5\n");
    my $edit = commit_file($dir, 'Edit a', 'a.txt' => "a1\nA2\nA3\nA4\na5\n");
    run_git($dir, qw/commit -q --allow-empty -m/, 'Empty');
    my ($empty) = run_git($dir, qw/rev-parse HEAD/) =~ m/(\S+)/;
    my $repo    = Review::Helper::VCS->detect($dir);
    my $db      = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(base => $base));
    my $dbh     = $db->dbh;

    my %entry = map { ($_->{revision} => $_->{id}) } @{rows($db, 'SELECT id, revision FROM commit_entry')};
    my $flag  = $dbh->prepare(q{INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, kind, sentence, created, pending) VALUES (?, ?, ?, ?, ?, 'yellow', 'note', 'S.', 5, ?)});
    $flag->execute('partly',  $entry{$edit},  'a.txt', 2,     4,     0);
    $flag->execute('pending', $entry{$edit},  'a.txt', 4,     4,     1);
    $flag->execute('empty',   $entry{$empty}, undef,   undef, undef, 0);
    $dbh->do(q{INSERT INTO flag_seen (flag, reviewer, at) SELECT id, 'Ann', 7 FROM flag WHERE pending = 0});

    # Amend the edit under the empty commit: line 2 changes again, a line
    # goes on top.
    run_git($dir, qw/reset -q --hard/, $base);
    my $amended = commit_file($dir, 'Edit a', 'a.txt' => "a0\na1\nB2\nA3\nA4\na5\n");
    run_git($dir, qw/commit -q --allow-empty -m/, 'Empty again');
    my ($empty2) = run_git($dir, qw/rev-parse HEAD/) =~ m/(\S+)/;
    is($CLASS->new(repo => $repo, db => $db)->iterate, 2, 'iteration 2');

    my $two = flags_of($db, 2);
    like($two->{partly},  {revision => $amended, line_start => 4, line_end => 5, pending => 1}, 'partly changed lines: the span the diff kept, moved');
    like($two->{pending}, {revision => $amended, line_start => 5, line_end => 5, pending => 1}, 'a flag already pending carries pending, moved');
    like($two->{empty},   {revision => $empty2, path => undef, pending => 1}, 'the empty commit was rewritten too: its flag goes on the last commit');

    my $items = sub ($all = 0) {
        +{map { ($_->{about}->{note} => $_) } grep { $_->{type} eq 'flag' } @{Review::Helper::Sheet->new(repo => $repo, db => $db)->sheet(all => $all)->{items}}};
    };
    is($items->()->{empty}->{about}->{rewritten}, T(), 'the rewritten empty commit reads as rewritten');

    # The agent keeps two, leaving the empty commit's undecided; Ann sees the
    # kept ones again.
    $dbh->do(q{UPDATE flag SET pending = 0 WHERE note_id <> 'empty'});
    $dbh->do(q{INSERT INTO flag_seen (flag, reviewer, at) SELECT f.id, 'Ann', 9 FROM flag f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = 2 AND f.pending = 0});

    # Nothing rewritten: both commits pair, the empty one by its revision.
    is($CLASS->new(repo => $repo, db => $db)->iterate, 3, 'iteration 3');
    my $three = flags_of($db, 3);
    is([sort keys %$three],                                        [qw/empty partly pending/], 'one flag per note, none doubled');
    is([map { $three->{$_}->{pending} } qw/empty partly pending/], [1, 0, 0],                  'kept flags carry settled, the undecided one stays pending');
    is($three->{empty}->{revision},                                $empty2,                    'the empty commit keeps its flag');
    is(seen_in($db, 3),                                            2,                          'kept flags keep their seen marks');
    my $three_items = $items->(1);
    is([map { $three_items->{$_}->{about}->{rewritten} } qw/empty partly pending/], [F(), F(), F()], 'none reads as rewritten: the empty commit paired by revision');
    is($three_items->{empty}->{about}->{pending},                                   T(),             'the undecided one is still asked about');
};

subtest rewritten_flag_onto_a_merge => sub {
    my $dir      = make_repo();
    my $base     = commit_file($dir, 'Base', 'a.txt' => "a\n", 'gone.txt' => "g\n");
    my $edit     = commit_file($dir, 'Edit gone', 'gone.txt' => "g1\n");
    my $repo     = Review::Helper::VCS->detect($dir);
    my $db       = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(base => $base));
    my ($old_id) = $db->dbh->selectrow_array('SELECT id FROM commit_entry');
    $db->dbh->do(q{INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, kind, sentence, created) VALUES ('g', ?, 'gone.txt', 1, 1, 'red', 'note', 'S.', 5)}, undef, $old_id);

    # Drop the edit; the new history ends in a merge.
    run_git($dir, qw/reset -q --hard/, $base);
    run_git($dir, qw/checkout -q -b side/);
    commit_file($dir, 'Side', 'b.txt' => "b\n");
    run_git($dir, qw/checkout -q main/);
    commit_file($dir, 'Main', 'a.txt' => "a1\n");
    run_git($dir, qw/merge -q --no-ff -m/, 'Merge side', 'side');
    my ($merge) = run_git($dir, qw/rev-parse HEAD/) =~ m/(\S+)/;
    is($CLASS->new(repo => $repo, db => $db)->iterate, 2, 'iteration 2');

    like(flags_of($db, 2)->{g}, {revision => $merge, path => 'gone.txt', line_start => undef, pending => 1}, 'no commit changes its file: the last commit, a merge here, the whole file');
};

subtest rewritten_flags_not_in_squashed_reviews => sub {
    my $dir  = make_repo();
    my $base = commit_file($dir, 'Base', 'a.txt' => "a1\na2\n");
    commit_file($dir, 'Edit a', 'a.txt' => "a1\nA2\n");
    my $repo     = Review::Helper::VCS->detect($dir);
    my $db       = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(base => $base, squash => 1));
    my ($old_id) = $db->dbh->selectrow_array('SELECT id FROM commit_entry');
    $db->dbh->do(q{INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, kind, sentence, created) VALUES ('s', ?, 'a.txt', 2, 2, 'yellow', 'note', 'S.', 5)}, undef, $old_id);

    run_git($dir, qw/commit -q --amend -m/, 'Amended');
    is($CLASS->new(repo => $repo, db => $db)->iterate,                                                                                                2, 'iteration 2');
    is($db->dbh->selectrow_array(q{SELECT COUNT(*) FROM flag f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = 2 AND f.note_id = 's'}), 1, 'the squashed carry moves it, once');
};

subtest resplit_explained_afresh => sub {
    my $dir  = make_repo();
    my $pm   = "package Foo;\nsub foo {\n}\nour \$X = 1;\nsub bar {\n}\n1;\n";
    my $base = commit_file($dir, 'Base', 'lib/Foo.pm' => $pm);
    my $add  = $pm =~ s/(our \$X = 1;\n)/$1our \$Y = 2;\n/r;
    commit_file($dir, 'Add Y', 'lib/Foo.pm' => $add);

    my $repo = Review::Helper::VCS->detect($dir);
    my $db   = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(base => $base));
    my $rows = sub ($iteration) {
        $db->dbh->selectall_arrayref('SELECT s.name, s.ranges, s.what FROM section s JOIN file_change f ON f.id = s.file_id JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = ? ORDER BY s.position', undef, $iteration);
    };
    my %unit = map { ($_->[0] => {name => $_->[0], package => 'Foo', lines => [$_->[1]]}) } ['header', [1, 1]], ['sub foo', [2, 3]], ['sub bar', [6, 7]], ['end', [8, 8]];
    fill_splits($repo, $db, sub ($about) { [values %unit, {name => 'globals', package => 'Foo', lines => [[4, 5]]}] });
    is(
        $rows->(1),
        [['header', '[[1,1]]', undef], ['sub foo', '[[2,3]]', undef], ['globals', '[[4,5]]', undef], ['sub bar', '[[6,7]]', undef], ['end', '[[8,8]]', undef]],
        'every section is kept, touched or not',
    );
    $db->dbh->do(q{UPDATE section SET what = 'S ' || name});

    # Rewritten so a new sub and a new section come before the changed one.
    run_git($dir, qw/reset -q --hard/, $base);
    commit_file($dir, 'Add Y and baz', 'lib/Foo.pm' => $add =~ s/(sub foo \{\n\}\n)/${1}our \$W = 0;\nsub baz {\n}\n/r);
    $CLASS->new(repo => $repo, db => $db)->iterate;
    is($rows->(2), [], 'a changed file starts unsplit');

    my @new = (
        @unit{'header', 'sub foo'},
        {name => 'our $W',  package => 'Foo', lines => [[4, 4]]},
        {name => 'sub baz', package => 'Foo', lines => [[5, 6]]},
        {name => 'globals', package => 'Foo', lines => [[7, 8]]},
        {%{$unit{'sub bar'}}, lines => [[9,  10]]},
        {%{$unit{end}},       lines => [[11, 11]]},
    );
    fill_splits($repo, $db, sub ($about) { \@new });
    is(
        [grep { defined $_->[2] } @{$rows->(2)}],
        [],
        'a re-split file is explained afresh: even a section that reads the same takes no explanation by content',
    );
};

subtest close_orphaned_requests => sub {
    my ($dir, $repo, $base, $one) = setup();
    my $db  = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(base => $base));
    my $dbh = $db->dbh;
    my $add = $dbh->prepare(q{INSERT INTO request (iteration, kind, target, revision, path, note, status, created) VALUES (1, ?, ?, ?, ?, ?, 'open', 1)});
    $add->execute(@$_) for ['split', 'file', $one, 'lib/Foo.pm', 'Split it.'], ['split', 'file', $one, 'gone.txt', undef], ['debate', 'file', $one, 'a.txt', 'Why?'];

    $CLASS->new(repo => $repo, db => $db)->iterate;
    is(rows($db, q{SELECT status FROM request WHERE kind = 'split'}), [{status => 'open'}, {status => 'open'}], 'requests on a commit the iteration still has stays open');

    # Replay the commit: the same change id, a new sha.
    run_git($dir, qw/reset -q --hard/, $base);
    commit_file($dir, 'Replayed', 'lib/Foo.pm' => $PM2, 'a.txt' => "a\nb\n", 'blob.dat' => "x\0z", 'bad.txt' => "ok\n\xff\xfe\n");
    $CLASS->new(repo => $repo, db => $db)->iterate;

    is(
        rows($db, 'SELECT kind, iteration, revision, path, note, status FROM request ORDER BY id'),
        [
            {kind => 'split',  iteration => 1, revision => $one, path => 'lib/Foo.pm', note => 'Split it. (closed: its commit was rewritten)', status => 'done'},
            {kind => 'split',  iteration => 1, revision => $one, path => 'gone.txt',   note => '(closed: its commit was rewritten)',           status => 'done'},
            {kind => 'debate', iteration => 1, revision => $one, path => 'a.txt',      note => 'Why?',                                         status => 'open'},
        ],
        'split requests on a rewritten commit are closed with a note, even with the same change id; debates are left alone',
    );
};

subtest pin_after_commit => sub {
    my ($dir, $repo, $base) = setup();
    my $db = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(base => $base));
    my $id = $db->review->{id};
    commit_file($dir, 'More', 'a.txt' => "more\n");

    my $mock = mock 'Review::Helper::DB' => (override => [txn => sub ($self, $code) { $self->dbh->begin_work; $code->(); $self->dbh->rollback; die "commit failed\n" }]);
    like(dies { $CLASS->new(repo => $repo, db => $db)->iterate }, qr/^commit failed$/, 'the failed commit is rethrown');
    $mock = undef;

    is($repo->pins($id), ["refs/review-helper/$id/1"], 'no ref pinned for the iteration that did not commit');
};

subtest squashed => sub {
    my ($dir, $repo, $base, $one) = setup();
    my $empty = $repo->empty_revision;
    my $db    = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(squash => 1, title => 'Whole'));

    is(rows($db, 'SELECT base, head, squashed, paths FROM iteration'), [{base => $empty, head => $one, squashed => 1, paths => undef}], 'the empty revision is the default base');
    my $commits = rows($db, 'SELECT * FROM commit_entry');
    is(scalar @$commits, 1, 'one combined entry');
    like($commits->[0], {position => 1, revision => $one, parent => undef, merge_id => undef, subject => "Caf\x{e9} change", change_id => undef}, 'head text, no parent, no change id');

    my %files = map { ($_->{path} => $_) } @{rows($db, 'SELECT * FROM file_change')};
    is([sort keys %files], [qw{a.txt bad.txt blob.dat lib/Foo.pm}], 'every file of the head');
    like($files{'lib/Foo.pm'}, {status => 'A', size_before => undef, size_after => 12, added => 12, split_source => 'none'}, 'files are added, not split');

    my $whole = $db;
    $db = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(squash => 1, base => $base, paths => ['lib', '*.txt']));
    is(rows($db, 'SELECT base, squashed, paths FROM iteration'), [{base => $base, squashed => 1, paths => '["lib","*.txt"]'}], 'base and paths stored');
    like(rows($db, 'SELECT parent FROM commit_entry'), [{parent => $base}], 'the base is the parent');
    is($db->dbh->selectall_arrayref('SELECT path, status FROM file_change ORDER BY path'), [['a.txt', 'M'], ['bad.txt', 'A'], ['lib/Foo.pm', 'M']], 'the combined change, limited to the paths');

    like(dies { $CLASS->new(repo => $repo)->build(squash => 1, base  => $one) },        qr/No changes in $one\.\.$one at /,         'nothing to review');
    like(dies { $CLASS->new(repo => $repo)->build(squash => 1, paths => ['nothing']) }, qr/No changes in .* under the given paths/, 'no matching paths');
    like(dies { $CLASS->new(repo => $repo)->build(squash => 1, paths => ['']) },        qr/'paths' must be an array of path specs/, 'paths checked');
    like(dies { $CLASS->new(repo => $repo)->build(base => $base, squash => 0, paths => 'lib') }, qr/'paths' must be an array of path specs/, 'paths must be an array');

    my $two = commit_file($dir, 'Two', 'lib/Foo.pm' => $PM, 'a.txt' => "c\n");
    is($CLASS->new(repo => $repo, db => $db)->iterate,                                     2,                                                                          'iterate');
    is(rows($db, 'SELECT base, head, squashed, paths FROM iteration WHERE number = 2'),    [{base => $base, head => $two, squashed => 1, paths => '["lib","*.txt"]'}], 'squash and paths reused');
    is($db->dbh->selectrow_array('SELECT COUNT(*) FROM commit_entry WHERE iteration = 2'), 1,                                                                          'still one entry');

    is($CLASS->new(repo => $repo, db => $whole)->iterate,                 2,                                'iterate a whole-codebase review');
    is(rows($whole, 'SELECT base, head FROM iteration WHERE number = 2'), [{base => $empty, head => $two}], 'still from the empty revision');
};

subtest squashed_carry => sub {
    my $dir  = make_repo();
    my $text = join '' => map { "line $_\n" } 1 .. 10;
    my $base = commit_file($dir, 'Base', 't.txt' => $text, 'u.txt' => "u\n");
    my $one  = commit_file($dir, 'One',  't.txt' => $text . "line 11\n", 'u.txt' => "u1\n", 'v.txt' => "v\n");
    my $repo = Review::Helper::VCS->detect($dir);
    my $db   = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(squash => 1, base => $base));
    my $dbh  = $db->dbh;

    my ($commit_id) = $dbh->selectrow_array('SELECT id FROM commit_entry');
    $dbh->do(q{UPDATE iteration SET what = 'Sum', why = 'SY', how = 'SH'});
    $dbh->do(q{UPDATE commit_entry SET what = 'W', why = 'Y', how = 'H', order_set = 1});
    $dbh->do(q{UPDATE file_change SET what = 'F ' || path, object_system = 'O', paradigms = 'P', read_position = id});
    for (['lines', 't.txt', 11, 11], ['changed', 't.txt', 4, 5], ['same', 'u.txt', undef, undef]) {
        $dbh->do(q{INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, kind, sentence, created) VALUES (?, ?, ?, ?, ?, 'red', 'note', 'S.', 5)}, undef, $_->[0],                                          $commit_id, @$_[1 .. 3]);
        $dbh->do('INSERT INTO flag_seen (flag, reviewer, at) VALUES (?, ?, ?)',                                                                                       undef, $dbh->last_insert_id(undef, undef, 'flag', 'id'), 'Alice',    100);
    }
    $dbh->do(q{INSERT INTO request (iteration, kind, target, revision, path, status, created) VALUES (1, 'split', 'file', ?, 't.txt', 'open', 1)}, undef, $one);

    my $flags = sub ($number) {
        $dbh->selectall_arrayref(<<'        EOT', {Slice => {}}, $number);
            SELECT f.note_id, f.line_start, f.line_end, f.pending, (SELECT count(*) FROM flag_seen r WHERE r.flag = f.id) AS marks
              FROM flag f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = ? ORDER BY f.id
        EOT
    };
    my $files = sub ($number) {
        +{map { ($_->{path} => $_) } @{rows($db, 'SELECT f.* FROM file_change f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = ?', $number)}};
    };

    # Two lines added above t.txt's flags and line 5 changed; u.txt and v.txt kept.
    my $two = commit_file($dir, 'Two', 't.txt' => "new 1\nnew 2\n" . ($text =~ s/line 5/line five/r) . "line 11\n");
    is($CLASS->new(repo => $repo, db => $db)->iterate, 2, 'iteration 2');
    is(
        $flags->(2),
        [
            {note_id => 'lines',   line_start => 13,    line_end => 13,    pending => 0, marks => 1},
            {note_id => 'changed', line_start => 6,     line_end => 6,     pending => 1, marks => 0},
            {note_id => 'same',    line_start => undef, line_end => undef, pending => 0, marks => 1},
        ],
        'flags carry between the squashed entries: moved lines keep their marks; changed lines are pending on the lines kept, without marks',
    );
    like(rows($db, 'SELECT what, why, how, order_set FROM commit_entry WHERE iteration = 2'), [{what => undef, why => undef, how => undef, order_set => 1}], 'entry text left empty; reading order kept with the same files');
    like(rows($db, 'SELECT what, why, how FROM iteration WHERE number = 2'), [{what => undef, why => undef, how => undef}], 'summary left empty');
    my $old = $files->(1);
    my $new = $files->(2);
    like($new->{'t.txt'},                                           {what => undef, object_system => undef, paradigms => undef, read_position => $old->{'t.txt'}->{read_position}}, 'changed file: no file text, reading position kept');
    like($new->{'u.txt'},                                           {what => 'F u.txt', object_system => 'O', paradigms => 'P'},                                                    'identical file: file text carried');
    like(rows($db, q{SELECT iteration, status, note FROM request}), [{iteration => 1, status => 'done', note => '(closed: its commit was rewritten)'}],                             'a split request on the old entry is closed');

    # A file added: the reading order no longer fits.
    commit_file($dir, 'Three', 'w.txt' => "w\n");
    $CLASS->new(repo => $repo, db => $db)->iterate;
    like(rows($db, 'SELECT order_set FROM commit_entry WHERE iteration = 3'), [{order_set => 0}], 'a file added: reading order not carried');
    is([grep { defined } map { $_->{read_position} } values %{$files->(3)}], [], 'no reading positions');
    is(scalar @{$flags->(3)},                                                3,  'flags still carried');

    # Another base: no pairing.
    $CLASS->new(repo => $repo, db => $db)->iterate(base => $one);
    is($flags->(4),                                                 [], 'another base: no flags carried');
    is([grep { defined } map { $_->{what} } values %{$files->(4)}], [], 'and no file text');
};

# A flag on a file a squashed change no longer touches (its change reverted)
# is pending even though its lines read the same, and its sheet item says so.
subtest flag_on_a_reverted_file => sub {
    my $dir  = make_repo();
    my $base = commit_file($dir, 'Base', 'r.txt' => "one\ntwo\nthree\n", 'k.txt' => "k\n");
    commit_file($dir, 'One', 'r.txt' => "one\ntwo\nTHREE\n", 'k.txt' => "k1\n");
    my $repo        = Review::Helper::VCS->detect($dir);
    my $db          = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(squash => 1, base => $base));
    my $dbh         = $db->dbh;
    my ($commit_id) = $dbh->selectrow_array('SELECT id FROM commit_entry');
    for (['reverted', 'r.txt', 1], ['kept', 'k.txt', 1]) {
        $dbh->do(q{INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, kind, sentence, created) VALUES (?, ?, ?, ?, ?, 'yellow', 'note', 'S.', 5)}, undef, $_->[0], $commit_id, $_->[1], $_->[2], $_->[2]);
        $dbh->do('INSERT INTO flag_seen (flag, reviewer, at) VALUES (?, ?, ?)', undef, $dbh->last_insert_id(undef, undef, 'flag', 'id'), 'Alice', 100);
    }

    # r.txt goes back to the base; line 1, the flagged one, never changed. k.txt only gains a line.
    commit_file($dir, 'Two', 'r.txt' => "one\ntwo\nthree\n", 'k.txt' => "k1\nk2\n");
    is($CLASS->new(repo => $repo, db => $db)->iterate, 2, 'iteration 2');
    is(
        $dbh->selectall_arrayref(<<'        EOT', {Slice => {}}),
            SELECT f.note_id, f.path, f.line_start, f.pending, (SELECT count(*) FROM flag_seen r WHERE r.flag = f.id) AS marks
              FROM flag f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = 2 ORDER BY f.id
        EOT
        [{note_id => 'reverted', path => 'r.txt', line_start => 1, pending => 1, marks => 0}, {note_id => 'kept', path => 'k.txt', line_start => 1, pending => 0, marks => 1}],
        'the flag on the reverted file is pending without marks, on its path and lines; the other carries as before',
    );

    my %items = map { ($_->{about}->{note} => $_) } grep { $_->{type} eq 'flag' } @{Review::Helper::Sheet->new(repo => $repo, db => $db)->sheet(all => 1)->{items}};
    is([map { $items{$_}->{about}->{left_change} } qw/reverted kept/], [T(), F()], 'the sheet says which file left the change');

    # The agent keeps it and Alice sees it; the next iteration carries it
    # settled, since the file left the change in iteration 2, not now.
    Review::Helper::Sheet->new(repo => $repo, db => $db)->fill({%{Review::Helper::Sheet->new(repo => $repo, db => $db)->sheet}, items => [{%{$items{reverted}}, fields => {decision => 'keep'}}]});
    my ($kept) = $dbh->selectrow_array(q{SELECT f.id FROM flag f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = 2 AND f.note_id = 'reverted'});
    $dbh->do(q{INSERT INTO flag_seen (flag, reviewer, at) VALUES (?, 'Alice', 200)}, undef, $kept);
    commit_file($dir, 'Three', 'k.txt' => "k1\nk2\nk3\n");
    is($CLASS->new(repo => $repo, db => $db)->iterate, 3, 'iteration 3');
    is(
        $dbh->selectall_arrayref(<<'        EOT', {Slice => {}}),
            SELECT f.path, f.pending, (SELECT count(*) FROM flag_seen r WHERE r.flag = f.id) AS marks
              FROM flag f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = 3 AND f.note_id = 'reverted'
        EOT
        [{path => 'r.txt', pending => 0, marks => 1}],
        'a kept flag on a file already outside the change carries settled, with its marks',
    );
};

# A file git finds renamed between the iterations takes its flags along: on
# the new path, still unchanged when only its name changed.
subtest flags_follow_renames => sub {
    my $dir  = make_repo();
    my $text = join '' => map { "line $_\n" } 1 .. 10;
    my $base = commit_file($dir, 'Base', 'keep.txt' => "k\n");
    commit_file($dir, 'One', 't.txt' => $text, 'u.txt' => $text =~ s/line/row/gr);
    my $repo        = Review::Helper::VCS->detect($dir);
    my $db          = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(squash => 1, base => $base));
    my $dbh         = $db->dbh;
    my ($commit_id) = $dbh->selectrow_array('SELECT id FROM commit_entry');

    for (['moved', 't.txt', 3, 4], ['changed', 'u.txt', 5, 5]) {
        $dbh->do(q{INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, kind, sentence, created) VALUES (?, ?, ?, ?, ?, 'red', 'note', 'S.', 5)}, undef, $_->[0], $commit_id, @$_[1 .. 3]);
        $dbh->do(q{INSERT INTO flag_seen (flag, reviewer, at) VALUES (?, 'Alice', 100)}, undef, $dbh->last_insert_id(undef, undef, 'flag', 'id'));
    }

    run_git($dir, qw/mv t.txt r.txt/);
    run_git($dir, qw/mv u.txt v.txt/);
    commit_file($dir, 'Rename', 'v.txt' => $text =~ s/line/row/gr =~ s/row 5/row five/r);
    $CLASS->new(repo => $repo, db => $db)->iterate;

    is(
        $dbh->selectall_arrayref(<<'        EOT', {Slice => {}}),
            SELECT f.note_id, f.path, f.line_start, f.line_end, f.pending, (SELECT count(*) FROM flag_seen r WHERE r.flag = f.id) AS marks,
                   (SELECT count(*) FROM file_change x WHERE x.commit_id = f.commit_id AND x.path = f.path) AS held
              FROM flag f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = 2 ORDER BY f.id
        EOT
        [
            {note_id => 'moved',   path => 'r.txt', line_start => 3,     line_end => 4,     pending => 0, marks => 1, held => 1},
            {note_id => 'changed', path => 'v.txt', line_start => undef, line_end => undef, pending => 1, marks => 0, held => 1},
        ],
        'a renamed file keeps its flags on its new path: unchanged with their marks, pending when the code under them changed',
    );
};

# In a squashed iteration split into topics, a renamed file waits in the
# entry with no topic; its flag goes there too, though its topic stays.
subtest flags_follow_renames_out_of_a_topic => sub {
    my $dir  = make_repo();
    my $text = join '' => map { "line $_\n" } 1 .. 10;
    my $base = commit_file($dir, 'Base', 'k.txt' => "k\n");
    commit_file($dir, 'One', 'a.txt' => "a\n", 't.txt' => $text, 'u.txt' => "u\n");
    my $repo = Review::Helper::VCS->detect($dir);
    my $db   = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(squash => 1, base => $base));
    my $dbh  = $db->dbh;
    my ($id) = $dbh->selectrow_array('SELECT id FROM commit_entry');
    $dbh->do(q{UPDATE commit_entry SET topic = 'A' WHERE id = ?},                                                                                                                      undef, $id);
    $dbh->do(q{INSERT INTO commit_entry (iteration, position, revision, subject, message, topic) SELECT iteration, 2, revision, subject, message, 'T' FROM commit_entry WHERE id = ?}, undef, $id);
    my $t = $dbh->last_insert_id(undef, undef, 'commit_entry', 'id');
    $dbh->do(q{UPDATE file_change SET commit_id = ? WHERE path IN ('t.txt', 'u.txt')},                                                                                    undef, $t);
    $dbh->do(q{INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, kind, sentence, created) VALUES ('m', ?, 't.txt', 3, 4, 'red', 'note', 'S.', 5)}, undef, $t);
    $dbh->do(q{INSERT INTO flag_seen (flag, reviewer, at) VALUES (?, 'me', 7)},                                                                                           undef, $dbh->last_insert_id(undef, undef, 'flag', 'id'));

    run_git($dir, qw/mv t.txt r.txt/);
    commit_file($dir, 'Two', 'a.txt' => "a2\n");
    $CLASS->new(repo => $repo, db => $db)->iterate;

    is(
        $dbh->selectall_arrayref(<<'        EOT', {Slice => {}}),
            SELECT f.path, f.line_start, f.line_end, f.pending, c.topic, (SELECT count(*) FROM flag_seen r WHERE r.flag = f.id) AS marks,
                   (SELECT count(*) FROM file_change x WHERE x.commit_id = f.commit_id AND x.path = f.path) AS held
              FROM flag f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = 2
        EOT
        [{path => 'r.txt', line_start => 3, line_end => 4, pending => 0, topic => undef, marks => 1, held => 1}],
        'the flag follows its file out of topic T, which still has a file, to the entry with no topic that holds it',
    );
};

subtest squashed_carry_edges => sub {
    my $dir  = make_repo();
    my $base = commit_file($dir, 'Base', 'lib/Foo.pm' => $PM, 'u.txt' => "u\n", 'd.txt' => "d\n");
    my $one  = commit_file($dir, 'One', 'lib/Foo.pm' => $PM2, 'u.txt' => "u1\n");
    run_git($dir, qw/rm -q d.txt/);
    run_git($dir, qw/commit -q -m/, 'Drop d');
    my $repo = Review::Helper::VCS->detect($dir);
    my $db   = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(squash => 1, base => $base));
    my $dbh  = $db->dbh;
    my ($commit_id, $head) = $dbh->selectrow_array('SELECT id, revision FROM commit_entry');

    my $split = sub ($about) { $about->{path} eq 'lib/Foo.pm' ? [@FOO_UNITS] : undef };
    fill_splits($repo, $db, $split);
    $dbh->do(q{UPDATE file_change SET what = 'F ' || path});
    $dbh->do(q{UPDATE section SET what = 'S ' || name});
    for (['deleted', 'd.txt', undef], ['dropped', 'u.txt', 1]) {
        $dbh->do(q{INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, kind, sentence, created) VALUES (?, ?, ?, ?, ?, 'red', 'note', 'S.', 5)}, undef, $_->[0], $commit_id, $_->[1], $_->[2], $_->[2]);
        $dbh->do('INSERT INTO flag_seen (flag, reviewer, at) VALUES (?, ?, ?)', undef, $dbh->last_insert_id(undef, undef, 'flag', 'id'), 'Alice', 100);
    }
    $dbh->do(q{INSERT INTO request (iteration, kind, target, revision, path, status, created) VALUES (1, 'split', 'file', ?, 'u.txt', 'open', 1)}, undef, $head);

    # Foo.pm changes one sub; u.txt goes back to the base, so the entry no longer changes it; d.txt stays deleted.
    commit_file($dir, 'Two', 'lib/Foo.pm' => $PM2 =~ s/    3;/    4;/r, 'u.txt' => "u\n");
    is($CLASS->new(repo => $repo, db => $db)->iterate, 2, 'iteration 2');

    my %files = map { ($_->{path} => $_) } @{rows($db, 'SELECT f.* FROM file_change f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = 2')};
    is([sort keys %files],                   [qw{d.txt lib/Foo.pm}], 'u.txt dropped out of the entry');
    is($files{'lib/Foo.pm'}->{split_source}, 'none',                 'the changed file starts unsplit');
    fill_splits($repo, $db, $split);
    my %whats = map { @$_ } @{$dbh->selectall_arrayref('SELECT name, what FROM section WHERE file_id = ?', undef, $files{'lib/Foo.pm'}->{id})};
    is([@whats{'sub keep', 'sub added', 'sub drop'}], [undef, undef, undef], 'split again, its sections start with no text');
    is($files{'lib/Foo.pm'}->{what},                  undef,                 'the changed file gets no file text');
    is($files{'d.txt'}->{what},                       'F d.txt',             'a file deleted in both entries counts as identical');

    is(
        $dbh->selectall_arrayref(<<'        EOT', {Slice => {}}),
            SELECT f.note_id, f.path, (SELECT count(*) FROM flag_seen r WHERE r.flag = f.id) AS marks
              FROM flag f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = 2 ORDER BY f.id
        EOT
        [{note_id => 'deleted', path => 'd.txt', marks => 1}, {note_id => 'dropped', path => 'u.txt', marks => 0}],
        'the deleted file keeps its flag and mark; a flag on a file that dropped out of the entry still carries',
    );
    like(rows($db, 'SELECT iteration, status, note FROM request'), [{iteration => 1, status => 'done', note => qr/closed/}], 'a split request on a file the entry no longer changes is closed');
};

subtest carry_file_lookups => sub {
    my ($dir, $repo, $base, $one) = setup();
    my $calls   = 0;
    my $mock    = mock 'Review::Helper::VCS::Git' => (around => [file_id => sub ($orig, @args) { $calls++; $orig->(@args) }]);
    my $builder = $CLASS->new(repo => $repo);

    my ($old, $new) = map { +{revision => $_, parent => $base} } $one, $one;
    my $file = {path => 'a.txt'};
    $builder->carry_file($file, {path => 'a.txt', split_source => 'none', what => 'W', read_position => 2}, $old, $new);
    is($file, {path => 'a.txt', what => 'W', object_system => undef, paradigms => undef, read_position => 2}, 'text and position carried');
    is($calls, 0, 'no content lookups for a commit with the same change id and no split');

    $file = {path => 'a.txt'};
    $builder->carry_file($file, {path => 'a.txt', split_source => 'agent', sections => ['S']}, $old, $new);
    is($calls,                              4,                'a split compares both sides');
    is([@$file{qw/split_source sections/}], ['agent', ['S']], 'and comes along when they read the same');

    $file = {path => 'a.txt'};
    $builder->carry_file($file, {path => 'a.txt', split_source => 'agent', sections => ['S']}, $old, {revision => $one, parent => $one});
    ok(!exists $file->{sections}, 'not when the file read otherwise before the commit');
};

# A squashed iteration split into topics pairs entries by topic name.
subtest squashed_topics_carry => sub {
    my $dir  = make_repo();
    my $base = commit_file($dir, 'Base', 'a.txt' => "a\n", 'b.txt' => "b\n", 'c.txt' => "c\n");
    commit_file($dir, 'One', 'a.txt' => "a1\n", 'b.txt' => "b1\n", 'c.txt' => "c1\n");
    my $repo = Review::Helper::VCS->detect($dir);
    my $db   = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(squash => 1, base => $base));
    my $dbh  = $db->dbh;

    # Topics as a fill leaves them: A holds a.txt and b.txt, C holds c.txt.
    my ($revision, $id) = $dbh->selectrow_array('SELECT revision, id FROM commit_entry');
    $dbh->do(q{UPDATE commit_entry SET topic = 'A', what = 'WA', why = 'YA', how = 'HA', order_set = 1 WHERE id = ?},                                                                                                                  undef, $id);
    $dbh->do(q{INSERT INTO commit_entry (iteration, position, revision, subject, message, topic, what, why, how, order_set) SELECT iteration, 2, revision, subject, message, 'C', 'WC', 'YC', 'HC', 1 FROM commit_entry WHERE id = ?}, undef, $id);
    my $c = $dbh->last_insert_id(undef, undef, 'commit_entry', 'id');
    $dbh->do(q{UPDATE file_change SET commit_id = ? WHERE path = 'c.txt'},                                                                       undef, $c);
    $dbh->do(q{INSERT INTO flag (note_id, commit_id, path, color, kind, sentence, created) VALUES ('on-c', ?, 'c.txt', 'red', 'note', 'S.', 5)}, undef, $c);

    my $entries = sub ($number) {
        rows($db, 'SELECT c.position, c.topic, c.what, c.order_set, f.path FROM commit_entry c JOIN file_change f ON f.commit_id = c.id WHERE c.iteration = ? ORDER BY c.position, f.path', $number);
    };

    # a.txt changes again, d.txt is new; c.txt reads the same.
    commit_file($dir, 'Two', 'a.txt' => "a2\n", 'd.txt' => "d\n");
    $CLASS->new(repo => $repo, db => $db)->iterate;
    is(
        $entries->(2),
        [
            {position => 1, topic => 'A',   what => undef, order_set => 1, path => 'a.txt'},
            {position => 1, topic => 'A',   what => undef, order_set => 1, path => 'b.txt'},
            {position => 2, topic => 'C',   what => 'WC',  order_set => 1, path => 'c.txt'},
            {position => 3, topic => undef, what => undef, order_set => 0, path => 'd.txt'},
        ],
        'files keep their topic and a new one waits in none; text carries only for a topic whose files all read the same, reading order for the same files',
    );
    is(rows($db, 'SELECT c.topic FROM flag f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = 2'), [{topic => 'C'}], 'a flag carries to the topic of the same name');

    # A whole-topic flag on C, marked reviewed.
    my ($c2) = $dbh->selectrow_array(q{SELECT id FROM commit_entry WHERE iteration = 2 AND topic = 'C'});
    $dbh->do(q{INSERT INTO flag (note_id, commit_id, color, kind, sentence, created) VALUES ('all-c', ?, 'red', 'other', 'All of C.', 6)}, undef, $c2);
    $dbh->do(q{INSERT INTO flag_seen (flag, reviewer, at) VALUES (?, 'me', 7)},                                                            undef, $dbh->last_insert_id(undef, undef, 'flag', 'id'));

    # c.txt goes back to the base: topic C has no file left.
    commit_file($dir, 'Three', 'c.txt' => "c\n");
    $CLASS->new(repo => $repo, db => $db)->iterate;
    is([map { $_->{topic} } @{rows($db, 'SELECT topic FROM commit_entry WHERE iteration = 3 ORDER BY position')}], ['A', undef], 'a topic left with no file goes');
    is(
        rows($db, 'SELECT f.note_id, c.topic, r.reviewer FROM flag f JOIN commit_entry c ON c.id = f.commit_id LEFT JOIN flag_seen r ON r.flag = f.id WHERE c.iteration = 3 ORDER BY f.note_id'),
        [{note_id => 'all-c', topic => 'A', reviewer => 'me'}, {note_id => 'on-c', topic => 'A', reviewer => undef}],
        'its flags go to the first entry, a whole-topic flag with its reviewed mark',
    );
};

subtest paths => sub {
    my ($dir, $repo, $base, $one) = setup();
    run_git($dir, qw/checkout -q -b side/);
    my $side = commit_file($dir, 'Side', 'docs/x.md' => "# X\n");
    run_git($dir, qw/checkout -q main/);
    my $two = commit_file($dir, 'Two', 'lib/Foo.pm' => $PM);
    run_git($dir, qw/merge -q --no-ff -m Merge side/);
    my $text = commit_file($dir, 'Text only', 'a.txt' => "z\n");

    my $db = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(base => $base, paths => ['lib/']));
    is(rows($db, 'SELECT squashed, paths FROM iteration'),                                            [{squashed => 0, paths => '["lib/"]'}], 'paths stored');
    is($db->dbh->selectall_arrayref('SELECT position, revision FROM commit_entry ORDER BY position'), [[1, $one], [2, $two]],                 'commits and merges that change no matching file are left out');
    is($db->dbh->selectall_arrayref('SELECT DISTINCT path FROM file_change'),                         [['lib/Foo.pm']],                       'only matching files');

    $db = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(base => $base, paths => ['docs']));
    my $merge = run_git($dir, qw/rev-parse HEAD~1/) =~ s/\n//r;
    is(
        $db->dbh->selectall_arrayref('SELECT c.revision, m.revision FROM commit_entry c LEFT JOIN commit_entry m ON m.id = c.merge_id ORDER BY c.position'),
        [[$side, $merge], [$merge, undef]],
        'a merge stays with the commits it brought in',
    );

    like(dies { $CLASS->new(repo => $repo)->build(base => $base, paths => ['none']) }, qr/No commits in .* change the given paths/, 'nothing matches');

    my $later = commit_file($dir, 'Later', 'docs/x.md' => "# Y\n");
    is($CLASS->new(repo => $repo, db => $db)->iterate(base => $text),   2,                                       'iterate');
    is(rows($db, 'SELECT head, paths FROM iteration WHERE number = 2'), [{head => $later, paths => '["docs"]'}], 'paths reused');
};

subtest submodule => sub {
    my ($sub_dir) = setup();
    my ($dir, $repo, $base, $one) = setup();
    run_git($dir, qw/-c protocol.file.allow=always submodule add -q/, $sub_dir, 'sm');
    run_git($dir, qw/commit -q -m/, 'Add submodule');
    my $bumped = commit_file($sub_dir, 'Bump', 'a.txt' => "bumped\n");
    run_git("$dir/sm", qw/-c protocol.file.allow=always pull -q origin main/);
    run_git($dir, qw/commit -q -am/, 'Bump submodule');

    my $db = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(base => $one));
    my @sm = @{rows($db, q{SELECT f.*, c.subject FROM file_change f JOIN commit_entry c ON c.id = f.commit_id WHERE f.path = 'sm' ORDER BY c.position})};
    is(
        [map { [@$_{qw/subject status kind size_unit size_before size_after split_source added removed changed/}] } @sm],
        [
            ['Add submodule',  'A', 'binary', 'bytes', undef, undef, 'none', 0, 0, 0],
            ['Bump submodule', 'M', 'binary', 'bytes', undef, undef, 'none', 0, 0, 0],
        ],
        'a submodule added and bumped is listed as a binary file with no sizes',
    );
    is(rows($db, 'SELECT name FROM section WHERE file_id IN (' . join(',' => map { $_->{id} } @sm) . ')'), [], 'no sections');
};

subtest merge_owners => sub {
    my $dir      = make_repo();
    my $repo     = Review::Helper::VCS->detect($dir);
    my $base     = commit_file($dir, 'Base', 'a.txt' => "a\n");
    my $revision = sub ($rev) { run_git($dir, 'rev-parse', $rev) =~ s/\n//r };

    # main: A1 A2 A3; feature: F1, a back-merge of main at A2, F2; then feature merged into main.
    my $a1 = commit_file($dir, 'A1', 'm1.txt' => "1\n");
    my $a2 = commit_file($dir, 'A2', 'm2.txt' => "2\n");
    run_git($dir, qw/checkout -q -b feature/, $base);
    my $f1 = commit_file($dir, 'F1', 'f1.txt' => "1\n");
    run_git($dir, qw/merge -q --no-ff -m Back/, $a2);
    my $back = $revision->('HEAD');
    my $f2   = commit_file($dir, 'F2', 'f2.txt' => "2\n");
    run_git($dir, qw/checkout -q main/);
    my $a3 = commit_file($dir, 'A3', 'm3.txt' => "3\n");
    run_git($dir, qw/merge -q --no-ff -m Merge feature/);
    my $merge = $revision->('HEAD');

    my %owner = map { ($_->{revision} => $_->{merge_revision}) } @{$CLASS->new(repo => $repo)->collect($base, $merge)};
    is(
        \%owner,
        {$a1 => undef, $a2 => undef, $a3 => undef, $merge => undef, $f1 => $merge, $back => $merge, $f2 => $merge},
        'a back-merge takes no mainline commit',
    );

    # feature2 merged into feature (inner), feature merged into main (outer).
    my $start = $revision->('HEAD');
    run_git($dir, qw/checkout -q -b outer/);
    my $o1 = commit_file($dir, 'O1', 'o1.txt' => "1\n");
    run_git($dir, qw/checkout -q -b inner/);
    my $i1 = commit_file($dir, 'I1', 'lib/i1.txt' => "1\n");
    run_git($dir, qw/checkout -q outer/);
    run_git($dir, qw/merge -q --no-ff -m Inner inner/);
    my $inner = $revision->('HEAD');
    run_git($dir, qw/checkout -q main/);
    my $m1 = commit_file($dir, 'M1', 'm4.txt' => "4\n");
    run_git($dir, qw/merge -q --no-ff -m Outer outer/);
    my $outer = $revision->('HEAD');

    %owner = map { ($_->{revision} => $_->{merge_revision}) } @{$CLASS->new(repo => $repo)->collect($start, $outer)};
    is(\%owner, {$m1 => undef, $outer => undef, $o1 => $outer, $inner => $outer, $i1 => $inner}, 'a nested merge keeps its commits');

    my $kept = $CLASS->new(repo => $repo)->collect($start, $outer, ['lib']);
    is([map { [$_->{revision}, $_->{merge_revision}] } @$kept], [[$i1, $inner], [$inner, $outer], [$outer, undef]], 'paths keep both merges around a matching inner commit');
};

subtest agent_split_needs_same_content => sub {
    my $dir  = make_repo();
    my $text = join '' => map { "line $_\n" } 1 .. 10;
    my $base = commit_file($dir, 'Base',       't.txt' => $text);
    my $one  = commit_file($dir, 'Add a line', 't.txt' => $text . "line 11\n");
    my $repo = Review::Helper::VCS->detect($dir);
    my $db   = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(base => $base));
    my $dbh  = $db->dbh;
    $dbh->do(q{UPDATE file_change SET split_source = 'agent', what = 'W'});
    my ($commit_id) = $dbh->selectrow_array('SELECT id FROM commit_entry');
    $dbh->do(q{INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, kind, sentence, created) VALUES (?, ?, ?, ?, ?, 'red', 'note', 'S.', 5)}, undef, @$_)
        for ['lines', $commit_id, 't.txt', 11, 11], ['changed', $commit_id, 't.txt', 4, 5], ['file', $commit_id, 't.txt', undef, undef], ['commit', $commit_id, undef, undef, undef];

    # The same patch on a base with lines added above it and line 5 changed:
    # same change id, other line numbers.
    run_git($dir, qw/reset -q --hard/, $base);
    my $other  = "new 1\nnew 2\n" . $text =~ s/line 5/line five/r;
    my $moved  = commit_file($dir, 'Lines above',      't.txt' => $other);
    my $replay = commit_file($dir, 'Add a line again', 't.txt' => "${other}line 11\n");
    is($repo->change_id($replay), $repo->change_id($one), 'same change id');

    $CLASS->new(repo => $repo, db => $db)->iterate(base => $moved);
    is(
        $dbh->selectrow_hashref('SELECT f.what, f.split_source FROM file_change f JOIN commit_entry c ON c.id = f.commit_id WHERE c.revision = ?', undef, $replay),
        {what => 'W', split_source => 'none'},
        'explanation carried, the agent split not',
    );
    is(
        $dbh->selectall_arrayref('SELECT note_id, path, line_start, line_end, pending FROM flag f JOIN commit_entry c ON c.id = f.commit_id WHERE c.revision = ? ORDER BY f.id', undef, $replay),
        [['lines', 't.txt', 13, 13, 0], ['changed', 't.txt', 6, 6, 1], ['file', 't.txt', undef, undef, 1], ['commit', undef, undef, undef, 0]],
        'flags carried: moved lines follow the move; changed code makes a flag pending, on the lines the diff kept',
    );
};

subtest carried_marks => sub {
    my $dir         = make_repo();
    my $text        = join '' => map { "line $_\n" } 1 .. 10;
    my $base        = commit_file($dir, 'Base', 't.txt' => $text, 'u.txt' => "u\n");
    my $one         = commit_file($dir, 'Add a line', 't.txt' => $text . "line 11\n");
    my $repo        = Review::Helper::VCS->detect($dir);
    my $db          = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(base => $base));
    my $dbh         = $db->dbh;
    my ($commit_id) = $dbh->selectrow_array('SELECT id FROM commit_entry');

    for (['lines', 't.txt', 11, 11], ['changed', 't.txt', 4, 5], ['file', 't.txt', undef, undef], ['commit', undef, undef, undef]) {
        $dbh->do(q{INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, kind, sentence, created) VALUES (?, ?, ?, ?, ?, 'red', 'note', 'S.', 5)}, undef, $_->[0], $commit_id, @$_[1 .. 3]);
        my $flag = $dbh->last_insert_id(undef, undef, 'flag', 'id');
        $dbh->do('INSERT INTO flag_seen (flag, reviewer, at) VALUES (?, ?, ?)', undef, $flag, @$_) for ['Alice', 100], ['Bob', 200];
    }

    my $marks = sub ($revision) {
        $dbh->selectall_arrayref(<<'        EOT', undef, $revision);
            SELECT f.note_id, r.reviewer, r.at FROM flag f JOIN commit_entry c ON c.id = f.commit_id JOIN flag_seen r ON r.flag = f.id
             WHERE c.revision = ? ORDER BY f.id, r.reviewer
        EOT
    };
    my @all = map { [$_, 'Alice', 100], [$_, 'Bob', 200] } qw/lines changed file commit/;

    # The same patch on a base that changed another file: t.txt reads the same.
    run_git($dir, qw/reset -q --hard/, $base);
    my $other = commit_file($dir, 'Other file',       'u.txt' => "u2\n");
    my $same  = commit_file($dir, 'Add a line again', 't.txt' => $text . "line 11\n");
    is($repo->change_id($same), $repo->change_id($one), 'same change id');
    $CLASS->new(repo => $repo, db => $db)->iterate(base => $other);
    is($marks->($same), \@all, 'identical file: every mark carried, each reviewer with its time');

    # Lines added above and line 5 changed: only flags whose lines survive keep their marks.
    run_git($dir, qw/reset -q --hard/, $base);
    my $changed = "new 1\nnew 2\n" . $text =~ s/line 5/line five/r;
    my $moved   = commit_file($dir, 'Lines above',      't.txt' => $changed);
    my $replay  = commit_file($dir, 'Add a line again', 't.txt' => "${changed}line 11\n");
    $CLASS->new(repo => $repo, db => $db)->iterate(base => $moved);
    is(
        $marks->($replay),
        [grep { $_->[0] eq 'lines' || $_->[0] eq 'commit' } @all],
        'moved but unchanged lines keep their marks; changed lines and the changed whole file lose them',
    );
};

subtest repeated_change_id => sub {
    my $dir  = make_repo();
    my $text = join '' => map { "line $_\n" } 1 .. 10;
    my $base = commit_file($dir, 'Base', 't.txt' => $text, 'u.txt' => "u\n");
    my @old  = (commit_file($dir, 'Add x', 't.txt' => "${text}x\n"), commit_file($dir, 'Drop x', 't.txt' => $text), commit_file($dir, 'Add x again', 't.txt' => "${text}x\n"));
    my $repo = Review::Helper::VCS->detect($dir);
    is($repo->change_id($old[2]), $repo->change_id($old[0]), 'the first and last commits share a change id');

    my $db  = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(base => $base));
    my $dbh = $db->dbh;
    for ([$old[0], 'first'], [$old[2], 'last']) {
        my ($commit_id) = $dbh->selectrow_array('SELECT id FROM commit_entry WHERE revision = ?', undef, $_->[0]);
        $dbh->do(q{INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, kind, sentence, created) VALUES (?, ?, 't.txt', 11, 11, 'red', 'note', 'S.', 5)}, undef, $_->[1], $commit_id);
        $dbh->do(q{INSERT INTO flag_seen (flag, reviewer, at) VALUES (?, 'Alice', 100)}, undef, $dbh->last_insert_id(undef, undef, 'flag', 'id'));
    }

    # The same three commits on a base that changed another file.
    run_git($dir, qw/reset -q --hard/, $base);
    my $other = commit_file($dir, 'Other file', 'u.txt' => "u2\n");
    my @new   = (commit_file($dir, 'Add x', 't.txt' => "${text}x\n"), commit_file($dir, 'Drop x', 't.txt' => $text), commit_file($dir, 'Add x again', 't.txt' => "${text}x\n"));
    $CLASS->new(repo => $repo, db => $db)->iterate(base => $other);

    my $flags = sub ($revision) {
        $dbh->selectall_arrayref(<<'        EOT', undef, $revision);
            SELECT f.note_id, r.reviewer FROM flag f JOIN commit_entry c ON c.id = f.commit_id LEFT JOIN flag_seen r ON r.flag = f.id
             WHERE c.revision = ? ORDER BY f.id
        EOT
    };
    is($flags->($new[0]), [['first', 'Alice']], 'the first replayed commit carries the first commit\'s flag and mark');
    is($flags->($new[2]), [['last',  'Alice']], 'the last carries the last one\'s');
};

subtest carried_marks_binary_and_one_side => sub {
    my $dir         = make_repo();
    my $text        = join '' => map { "line $_\n" } 1 .. 10;
    my $base        = commit_file($dir, 'Base', 't.txt' => $text, 'img.bin' => "\0\1\2\n", 'gone.txt' => "g\n");
    my $one         = commit_file($dir, 'Add a line', 't.txt' => $text . "line 11\n");
    my $repo        = Review::Helper::VCS->detect($dir);
    my $db          = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(base => $base));
    my $dbh         = $db->dbh;
    my ($commit_id) = $dbh->selectrow_array('SELECT id FROM commit_entry');

    for (['bin-file', 'img.bin', undef, undef], ['bin-lines', 'img.bin', 1, 1], ['gone', 'gone.txt', undef, undef], ['kept', 't.txt', 11, 11]) {
        $dbh->do(q{INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, kind, sentence, created) VALUES (?, ?, ?, ?, ?, 'red', 'note', 'S.', 5)}, undef, $_->[0],                                          $commit_id, @$_[1 .. 3]);
        $dbh->do('INSERT INTO flag_seen (flag, reviewer, at) VALUES (?, ?, ?)',                                                                                       undef, $dbh->last_insert_id(undef, undef, 'flag', 'id'), 'Alice',    100);
    }

    # The same patch on a base that rewrote the binary and dropped gone.txt.
    run_git($dir, qw/reset -q --hard/, $base);
    my $other  = commit_file($dir, 'Rewrite and drop', 'img.bin' => "\0\3\4\n", 'gone.txt' => undef);
    my $replay = commit_file($dir, 'Add a line again', 't.txt'   => $text . "line 11\n");
    $CLASS->new(repo => $repo, db => $db)->iterate(base => $other);

    my $flags = $dbh->selectall_arrayref(<<'    EOT', undef, $replay);
        SELECT f.note_id, f.line_start, f.pending, (SELECT count(*) FROM flag_seen r WHERE r.flag = f.id)
          FROM flag f JOIN commit_entry c ON c.id = f.commit_id WHERE c.revision = ? ORDER BY f.id
    EOT
    is(
        $flags,
        [['bin-file', undef, 1, 0], ['bin-lines', undef, 1, 0], ['gone', undef, 1, 0], ['kept', 11, 0, 1]],
        'a changed binary and a file on one side only cannot be compared: pending whole-file flags, no marks',
    );
};

subtest line_moves => sub {
    my ($dir, $repo, $base, $one) = setup();
    my $builder = $CLASS->new(repo => $repo);

    my $del1 = commit_file($dir, 'Drop a', 'a.txt' => undef);
    run_git($dir, qw/reset -q --hard/, $base);
    my $mid  = commit_file($dir, 'Same a', 'a.txt' => "a\nb\n");
    my $del2 = commit_file($dir, 'Drop a', 'a.txt' => undef);
    run_git($dir, qw/reset -q --hard/, $base);
    my $del3 = commit_file($dir, 'Drop a', 'a.txt' => undef);

    my $moves = sub (@args) { my $hunks = $builder->line_moves(@args); defined($hunks) ? scalar(@$hunks) : undef };
    is($moves->({revision => $one,  parent => $base}, {revision => $one,  parent => $base}, 'a.txt'), 0,     'one commit');
    is($moves->({revision => $one,  parent => $base}, {revision => $mid,  parent => $base}, 'a.txt'), 0,     'same content');
    is($moves->({revision => $one,  parent => $base}, {revision => $base, parent => undef}, 'a.txt'), 1,     'other content: the hunks between them');
    is($moves->({revision => $del1, parent => $one},  {revision => $del2, parent => $mid},  'a.txt'), 0,     'deleted from the same content');
    is($moves->({revision => $del1, parent => $one},  {revision => $del3, parent => $base}, 'a.txt'), 1,     'deleted from other content');
    is($moves->({revision => $del1, parent => $one},  {revision => $one,  parent => $base}, 'a.txt'), undef, 'deleted on one side only');

    run_git($dir, qw/reset -q --hard/, $base);
    my $bin1 = commit_file($dir, 'Binary', 'b.bin' => "\0\1\n");
    my $bin2 = commit_file($dir, 'Binary', 'b.bin' => "\0\2\n");
    is($moves->({revision => $bin1, parent => $base}, {revision => $bin2, parent => $bin1}, 'b.bin'), undef, 'a changed binary file');
};

subtest decode_text => sub {
    my ($dir, $repo) = setup();
    my $builder = $CLASS->new(repo => $repo);
    is($builder->decode_text(undef),         undef,        'undef');
    is($builder->decode_text("caf\xc3\xa9"), "caf\x{e9}",  'utf-8');
    is($builder->decode_text("a\xffb"),      "a\x{fffd}b", 'malformed bytes replaced');
};

# Notes without a flag go straight into the new iteration's journal and
# leave the worktree's journal; notes with one wait for placement.
subtest journal_entries => sub {
    my $dir     = make_repo();
    my $base    = commit_file($dir, 'Base', 'a.txt' => "a\n");
    my $repo    = Review::Helper::VCS->detect($dir);
    my $journal = Review::Helper::Journal->new(repo => $repo);
    commit_file($dir, 'One', 'a.txt' => "b\n");
    my $entry = $journal->add(kind => 'note',   path => 'a.txt', unit     => 'x', snippet => 'b', sentence => 'FYI one.', detail => 'More.');
    my $flag  = $journal->add(flag => 'yellow', path => 'a.txt', sentence => 'A flag to place.');

    my $db = Review::Helper::DB->open($CLASS->new(repo => $repo)->build(base => $base));
    is(
        rows($db, 'SELECT * FROM journal_entry'),
        [{id => $entry, iteration => 1, kind => 'note', path => 'a.txt', unit => 'x', sentence => 'FYI one.', detail => 'More.', created => match qr/^\d+$/}],
        'build takes the journal entries into iteration 1, without their snippet',
    );
    is([map { $_->{id} } @{$journal->notes}], [$flag], 'they leave the journal; the flag note waits for placement');

    my $two = $journal->add(path => 'a.txt', sentence => 'FYI two.');
    commit_file($dir, 'Two', 'a.txt' => "c\n");
    $CLASS->new(repo => $repo, db => $db)->iterate;
    is(
        $db->dbh->selectall_arrayref('SELECT id, iteration, kind FROM journal_entry ORDER BY iteration'),
        [[$entry, 1, 'note'], [$two, 2, 'other']],
        'iterate takes the new ones into iteration 2; entries are not carried',
    );
    is([map { $_->{id} } @{$journal->notes}], [$flag], 'and they leave the journal');

    # A removal that failed after the commit leaves a taken entry behind.
    open(my $fh, '>>', $journal->path) or die "Cannot append: $!";
    print $fh Cpanel::JSON::XS->new->encode({id => $two, created => 1, kind => 'other', path => 'a.txt', sentence => 'FYI two.'}), "\n";
    close($fh);
    commit_file($dir, 'Three', 'a.txt' => "d\n");
    $CLASS->new(repo => $repo, db => $db)->iterate;
    is($db->dbh->selectall_arrayref('SELECT iteration FROM journal_entry WHERE id = ?', undef, $two), [[2]],   'an entry already taken keeps its iteration');
    is([map { $_->{id} } @{$journal->notes}],                                                         [$flag], 'and leaves the journal');

    # A bad entry (a hand edit, another tool) is skipped with a warning and
    # left in the journal; it does not block the iteration.
    open($fh, '>>', $journal->path) or die "Cannot append: $!";
    print $fh Cpanel::JSON::XS->new->encode($_), "\n"
        for { id => 'no-sentence', created => 1, kind => 'note', path => 'a.txt' }
    , {id => 'bad-kind', created => 1, kind => 'guess', path => 'a.txt', sentence => 'S.'};
    close($fh);
    my $good = $journal->add(path => 'a.txt', sentence => 'Fine.');
    commit_file($dir, 'Four', 'a.txt' => "e\n");
    my $warnings = warnings { $CLASS->new(repo => $repo, db => $db)->iterate };
    is($warnings,                                                                                      [match qr/^Skipping journal entry no-sentence: Note field 'sentence' is required$/, match qr/^Skipping journal entry bad-kind: Note kind must be one of: /], 'bad entries are skipped with a warning');
    is($db->dbh->selectall_arrayref('SELECT iteration FROM journal_entry WHERE id = ?', undef, $good), [[4]],                                                                                                                                                       'the good one is taken');
    is([sort map { $_->{id} } @{$journal->notes}],                                                     [sort $flag, 'no-sentence', 'bad-kind'],                                                                                                                     'the bad ones stay in the journal');

    # The iteration is in before the entries leave the journal: a failed
    # removal warns, and the iteration stands.
    my $late = $journal->add(path => 'a.txt', sentence => 'Late.');
    commit_file($dir, 'Five', 'a.txt' => "f\n");
    my $mock = mock 'Review::Helper::Journal' => (override => [remove => sub { die "boom\n" }]);
    my $number;
    $warnings = warnings { $number = $CLASS->new(repo => $repo, db => $db)->iterate };
    undef $mock;
    is($number,                                                                                        5,                                                                                                                                                'iteration 5 is made');
    is($warnings,                                                                                      [match qr/^Skipping journal entry /, match qr/^Skipping journal entry /, "Could not remove the stored journal entries from the journal: boom\n"], 'a failed removal only warns');
    is($db->dbh->selectall_arrayref('SELECT iteration FROM journal_entry WHERE id = ?', undef, $late), [[5]],                                                                                                                                            'with the entry stored');

    # A build too keeps its review file.
    my $built;
    $mock     = mock 'Review::Helper::Journal' => (override => [remove => sub { die "boom\n" }]);
    $warnings = warnings { $built = $CLASS->new(repo => $repo)->build(base => $base, file => "$dir/.git/review-helper/second.sqlite") };
    undef $mock;
    ok(-e $built, 'a build whose removal failed keeps its review file');
    is($warnings->[-1], "Could not remove the stored journal entries from the journal: boom\n", 'and warns');
};

done_testing;
