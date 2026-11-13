# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use Cpanel::JSON::XS();
use File::Temp qw/tempdir/;
use TestRepo qw/make_repo commit_file run_git/;
use TestSplit qw/fill_splits/;
use Review::Helper::Builder;
use Review::Helper::DB;
use Review::Helper::Journal;
use Review::Helper::Feedback;
use Review::Helper::VCS;
use Review::Helper::Sheet;

my $CLASS = 'Review::Helper::Sheet';
my $JSON  = Cpanel::JSON::XS->new->canonical;
my $TRUE  = Cpanel::JSON::XS::true();

my $PM = <<'EOT';
package Foo;

sub one {
    return 1;
}

sub two {
    return 2;
}

1;
EOT

my $CSS = join '' => map { "a$_ { color: red; }\n" } 1 .. 8;

# The agent's split of setup()'s files: every line of lib/Foo.pm, and
# style.scss left whole.
sub split_setup($about) {
    return [map { +{name => $_->[0], package => 'Foo', lines => [$_->[1]]} } ['header', [1, 1]], ['sub one', [3, 5]], ['sub two', [7, 9]], ['end', [11, 11]]] if $about->{path} eq 'lib/Foo.pm';
    return [];
}

# A review of one commit changing lib/Foo.pm and style.scss, plus a journal
# note; both files split unless 'split' is false.
sub setup(%params) {
    my $dir      = make_repo();
    my $base     = commit_file($dir, 'Base',   'lib/Foo.pm' => $PM, 'style.scss' => $CSS, 'keep.txt' => "k\nk\nk\n", 'logo.png' => "\x89PNG\0");
    my $revision = commit_file($dir, 'Change', 'lib/Foo.pm' => $PM =~ s/return 1/return 10/r =~ s/return 2/return 20/r, 'style.scss' => $CSS =~ s/a2 \{ color: red/a2 { color: blue/r);

    my $repo    = Review::Helper::VCS->detect($dir);
    my $journal = Review::Helper::Journal->new(repo => $repo);
    my $note    = $journal->add(flag => 'red', kind => 'deviation', path => 'lib/Foo.pm', unit => 'one', sentence => 'One changed.');

    my $file  = Review::Helper::Builder->new(repo => $repo)->build(base => $base);
    my $db    = Review::Helper::DB->open($file);
    my $sheet = $CLASS->new(repo => $repo, db => $db);
    fill_splits($repo, $db, \&split_setup) if $params{split} // 1;
    return {dir => $dir, repo => $repo, db => $db, revision => $revision, note => $note, sheet => $sheet, journal => $journal};
}

sub items_by_id($data) {
    +{map { ($_->{id} => $_) } @{$data->{items}}};
}

# A sheet holding only the given items, each with these fields set.
sub partial($data, %fill) {
    my $items = items_by_id($data);
    my @items;
    for my $id (sort keys %fill) {
        my $item = $items->{$id} or die "no item $id";
        push @items => {%$item, fields => {%{$item->{fields}}, %{$fill{$id}}}};
    }
    return {%$data, items => \@items};
}

sub errors_of($sheet, $data) {
    my $err = dies { $sheet->fill($data) };
    $err //= '';
    my ($head, @lines) = split /\n/ => $err;
    is($head, 'The sheet was rejected:', 'rejected') if $err;
    return \@lines;
}

subtest constructor => sub {
    like(dies { $CLASS->new },              qr/'repo' is a required attribute/, 'needs a repo');
    like(dies { $CLASS->new(repo => 'x') }, qr/'db' is a required attribute/,   'needs a db');
};

subtest sheet => sub {
    my $t           = setup();
    my $data        = $t->{sheet}->sheet;
    my ($commit_id) = $t->{db}->dbh->selectrow_array('SELECT id FROM commit_entry');
    my %file_ids    = map { @$_ } @{$t->{db}->dbh->selectall_arrayref('SELECT path, id FROM file_change')};

    is([@$data{qw/format format_version review iteration/}], ['review-sheet', 1, $t->{db}->review->{id}, 1], 'header');

    my $items = items_by_id($data);
    is(
        [map { $_->{id} } @{$data->{items}}],
        [
            'summary:1',                    "commit:$commit_id",      "order:$commit_id",
            "file:$file_ids{'lib/Foo.pm'}", match(qr/^section:\d+$/), match(qr/^section:\d+$/),
            "file:$file_ids{'style.scss'}", "note:$t->{note}",
            'guide:1',
        ],
        'items in order'
    );

    is($items->{'summary:1'},                 {id => 'summary:1', type => 'summary', rev => match(qr/^[0-9a-f]{64}$/), about => {base => T(), head => $t->{revision}, title => undef, squashed => F(), paths => undef}, fields => {what => undef, why => undef, how => undef}}, 'summary item');
    is($items->{"order:$commit_id"}->{about}, {commit => $t->{revision}, paths => ['lib/Foo.pm', 'style.scss']},                                                                                                                                                                'order about');
    is($items->{"note:$t->{note}"}->{about},  {flag => 'red', kind => 'deviation', path => 'lib/Foo.pm', unit => 'one', snippet => undef, sentence => 'One changed.', detail => undef},                                                                                         'note about');
    is($items->{'guide:1'}->{about},          {commits => [$t->{revision}]},                                                                                                                                                                                                    'guide about');

    my ($section) = grep { $_->{type} eq 'section' && $_->{about}->{name} eq 'sub one' } @{$data->{items}};
    is($section->{about}, {commit => $t->{revision}, path => 'lib/Foo.pm', name => 'sub one', package => 'Foo', ranges => [[3, 6]], doc_ranges => [], old_ranges => [], deleted => 0, added => 0, removed => 0, changed => 1}, 'section about');

    is($t->{sheet}->sheet, $data, 'stable');
    $t->{db}->dbh->do(q{UPDATE iteration SET what = 'W'});
    my $again = items_by_id($t->{sheet}->sheet);
    is($again->{'summary:1'}->{fields}, {what => 'W', why => undef, how => undef}, 'partly filled item keeps its values');
    isnt($again->{'summary:1'}->{rev}, $items->{'summary:1'}->{rev}, 'rev follows field values');
    is($again->{"commit:$commit_id"}->{rev}, $items->{"commit:$commit_id"}->{rev}, 'other revs unchanged');

    $t->{db}->dbh->do(q{UPDATE iteration SET why = 'Y', how = 'H'});
    ok(!items_by_id($t->{sheet}->sheet)->{'summary:1'}, 'done items are left out');
};

subtest optional_items => sub {
    my $t    = setup();
    my $data = items_by_id($t->{sheet}->sheet);
    is($data->{"note:$t->{note}"}->{optional}, $TRUE, 'notes are optional');
    ok(!(grep { $_->{optional} } grep { $_->{type} eq 'section' } values %$data), 'sections are required in a history review');
    is(
        errors_of($t->{sheet}, partial($t->{sheet}->sheet, 'summary:1' => {note => 'x'})),
        ["summary:1: unknown field 'note'"],
        'no iteration note on the first iteration',
    );

    my $squashed = Review::Helper::DB->open(Review::Helper::Builder->new(repo => $t->{repo})->build(squash => 1, paths => ['lib']));
    my $sheet    = $CLASS->new(repo => $t->{repo}, db => $squashed, journal => $t->{journal});
    my $items    = items_by_id($sheet->sheet);
    is($items->{'summary:1'}->{about}, hash { field squashed => T(); field paths => ['lib']; etc }, 'summary about names the squash and paths');
    my @splits = grep { $_->{type} eq 'split' } values %$items;
    ok(@splits && !(grep { !$_->{optional} } @splits), 'splits are optional in a squashed review');

    fill_splits($t->{repo}, $squashed, \&split_setup);
    $items = items_by_id($sheet->sheet);
    my @sections = grep { $_->{type} eq 'section' } values %$items;
    ok(@sections && !(grep { !$_->{optional} } @sections), 'sections are optional in a squashed review');
    my @orders = grep { $_->{type} eq 'order' } values %$items;
    ok(@orders && !(grep { !$_->{optional} } @orders), 'reading order is optional in a squashed review');

    my $result = $sheet->fill({%{$sheet->sheet}, items => []});
    is($result->{remaining}, scalar(grep { !$_->{optional} } values %$items), 'optional items do not count as remaining');
};

subtest iteration_note => sub {
    my $t   = setup();
    my $dbh = $t->{db}->dbh;
    commit_file($t->{dir}, 'More', 'keep.txt' => "k\n");
    Review::Helper::Builder->new(repo => $t->{repo}, db => $t->{db})->iterate;

    my $data = $t->{sheet}->sheet;
    is(items_by_id($data)->{'summary:2'}->{fields},                         {what => undef, why => undef, how => undef, note => undef}, 'summary takes a note from iteration 2');
    is(errors_of($t->{sheet}, partial($data, 'summary:2' => {note => ''})), ["summary:2: 'note' must be a non-empty string or null"],   'note checked');

    $t->{sheet}->fill(partial($data, 'summary:2' => {what => 'W', why => 'Y', how => 'H'}));
    ok(!items_by_id($t->{sheet}->sheet)->{'summary:2'}, 'the note is optional');

    $dbh->do(q{UPDATE iteration SET what = NULL WHERE number = 2});
    $t->{sheet}->fill(partial($t->{sheet}->sheet, 'summary:2' => {what => 'W', note => 'Fixed the tests.'}));
    is($dbh->selectrow_hashref('SELECT what, note FROM iteration WHERE number = 2'), {what => 'W', note => 'Fixed the tests.'}, 'note written to the iteration');
};

subtest header_errors => sub {
    my $t = setup();
    is(errors_of($t->{sheet}, []), ['The sheet must be a JSON object'], 'not an object');
    is(
        errors_of($t->{sheet}, {format => 'x', format_version => 2, review => 'r', iteration => 9, items => {}}),
        ["'format' must be 'review-sheet'", "'format_version' must be 1", 'The sheet is for another review', 'The sheet is not for the latest iteration, 1', "'items' must be an array"],
        'header checked',
    );
};

subtest item_errors => sub {
    my $t           = setup();
    my $data        = $t->{sheet}->sheet;
    my ($commit_id) = $t->{db}->dbh->selectrow_array('SELECT id FROM commit_entry');

    my ($file_id) = $t->{db}->dbh->selectrow_array(q{SELECT id FROM file_change WHERE path = 'lib/Foo.pm'});
    my $bad       = partial($data, 'summary:1' => {what => '', why => [], bogus => 1}, "commit:$commit_id" => {what => 'x'}, "order:$commit_id" => {paths => ['style.scss']}, "file:$file_id" => {what => 'valid'});
    my $bad_items = items_by_id($bad);
    $bad_items->{'summary:1'}->{rev}          = 'old';
    $bad_items->{"commit:$commit_id"}->{type} = 'file';
    push @{$bad->{items}} => 'x', {id => 'nope', fields => {what => 'x'}}, {id => 'summary:1', fields => 'x'}, {id => 'guide:1', fields => {steps => undef}};

    is(
        errors_of($t->{sheet}, $bad),
        bag {
            item "commit:$commit_id: type must be 'commit'";
            item "summary:1: stale revision; get a new sheet";
            item "summary:1: unknown field 'bogus'";
            item "Item 5 must be an object with an 'id'";
            item 'nope: unknown item';
            item "summary:1: 'fields' must be an object";
            item "order:$commit_id: 'paths' must list every path of the commit exactly once";
            end;
        },
        'every problem named',
    );
    is($t->{db}->dbh->selectrow_array('SELECT what FROM commit_entry'),                              undef, 'nothing written');
    is($t->{db}->dbh->selectrow_array('SELECT what FROM file_change WHERE id = ?', undef, $file_id), undef, 'not even the valid item');

    my $twice = partial($data, "commit:$commit_id" => {what => 'x'});
    push @{$twice->{items}} => $twice->{items}->[0];
    is(errors_of($t->{sheet}, $twice), ["commit:$commit_id: listed more than once"], 'duplicates');

    is(errors_of($t->{sheet}, partial($data, 'summary:1'        => {what  => '', why => []})), ["summary:1: 'what' must be a non-empty string or null", "summary:1: 'why' must be a non-empty string or null"], 'text fields');
    is(errors_of($t->{sheet}, partial($data, "order:$commit_id" => {paths => 'x'})),           ["order:$commit_id: 'paths' must be an array of paths"],                                                         'order type');
};

subtest text_fields => sub {
    my $t           = setup();
    my $data        = $t->{sheet}->sheet;
    my $dbh         = $t->{db}->dbh;
    my ($commit_id) = $dbh->selectrow_array('SELECT id FROM commit_entry');
    my ($file_id)   = $dbh->selectrow_array(q{SELECT id FROM file_change WHERE path = 'lib/Foo.pm'});
    my ($section)   = grep { $_->{type} eq 'section' } @{$data->{items}};

    is(errors_of($t->{sheet}, partial($data, "file:$file_id" => {paradigms => ''})), ["file:$file_id: 'paradigms' must be a non-empty string or null"], 'a file item without what still has its fields checked');
    my $skipped = $t->{sheet}->fill(partial($data, "file:$file_id" => {paradigms => 'OOP'}));
    is($skipped->{filled},                                                                       0,     "a file item without 'what' is not filled");
    is($dbh->selectrow_array('SELECT paradigms FROM file_change WHERE id = ?', undef, $file_id), undef, 'nothing is written');
    ok((grep { $_->{id} eq "file:$file_id" } @{$t->{sheet}->sheet->{items}}), 'and it stays to do');

    my $result = $t->{sheet}->fill(partial(
        $data,
        'summary:1'         => {what  => 'W',  why       => "Caf\x{e9}"},
        "commit:$commit_id" => {what  => 'CW', why       => 'CY', how => 'CH'},
        "file:$file_id"     => {what  => 'FW', paradigms => 'OOP'},
        $section->{id}      => {what  => 'SW'},
        "order:$commit_id"  => {paths => ['style.scss', 'lib/Foo.pm']},
        'guide:1'           => {steps => undef},
    ));
    is($result->{filled}, 5, 'all-null item skipped, the rest filled');

    is($dbh->selectrow_hashref('SELECT what, why, how FROM iteration'),                                                 {what => 'W', why => "Caf\x{e9}", how => undef},            'summary, only given fields');
    is($dbh->selectrow_hashref('SELECT what, why, how, order_set FROM commit_entry'),                                   {what => 'CW', why => 'CY', how => 'CH', order_set => 1},   'commit');
    is($dbh->selectrow_hashref('SELECT what, object_system, paradigms FROM file_change WHERE id = ?', undef, $file_id), {what => 'FW', object_system => undef, paradigms => 'OOP'}, 'file');
    is($dbh->selectrow_array('SELECT what FROM section WHERE id = ?', undef, $section->{id} =~ s/^section://r),         'SW',                                                       'section');
    is($dbh->selectall_arrayref('SELECT path, read_position FROM file_change ORDER BY read_position'),                  [['style.scss', 1], ['lib/Foo.pm', 2]],                     'reading order');

    my $left = items_by_id($t->{sheet}->sheet);
    is($left->{'summary:1'}->{fields}, {what => 'W', why => "Caf\x{e9}", how => undef}, 'summary still listed with its values');
    ok(!$left->{"commit:$commit_id"} && !$left->{"order:$commit_id"} && !$left->{"file:$file_id"} && !$left->{$section->{id}}, 'done items gone');
    is($result->{remaining}, scalar(grep { !$_->{optional} } values %$left), 'remaining counts required items left');
    my $more = $t->{sheet}->fill(partial($t->{sheet}->sheet(all => 1), "file:$file_id" => {object_system => 'Moo'}));
    is([$more->{filled}, $dbh->selectrow_array('SELECT what FROM file_change WHERE id = ?', undef, $file_id)], [1, 'FW'], "once it has one, other fields fill alone");
};

subtest notes => sub {
    my $t        = setup();
    my $data     = $t->{sheet}->sheet;
    my $id       = "note:$t->{note}";
    my $revision = $t->{revision};

    my %cases = (
        "'commit' is required to place a note"                                                                  => {path   => 'lib/Foo.pm'},
        "'commit': must be a commit's revision id"                                                              => {commit => ['zz']},
        "'commit': 'abcdef0' is not a commit of this iteration; give its full revision id"                      => {commit => 'abcdef0'},
        "'commit': '${\ substr($revision, 0, 8)}' is not a commit of this iteration; give its full revision id" => {commit => substr($revision, 0, 8)},
        "'commit': '${\ uc $revision}' is not a commit of this iteration; give its full revision id"            => {commit => uc $revision},
        "'lines' needs a 'path'"                                                                                => {commit => $revision, lines => [1, 2]},
        "'path': 'x' is not changed in commit $revision"                                                        => {commit => $revision, path  => 'x'},
        "'lines': must be [start, end]"                                                                         => {commit => $revision, path  => 'lib/Foo.pm', lines => [0, 2]},
        "'lines': start is after end"                                                                           => {commit => $revision, path  => 'lib/Foo.pm', lines => [3, 2]},
        "'lines': beyond the end of 'lib/Foo.pm' (11 lines)"                                                    => {commit => $revision, path  => 'lib/Foo.pm', lines => [3, 12]},
    );
    for my $error (sort keys %cases) {
        is(errors_of($t->{sheet}, partial($data, $id => $cases{$error})), ["$id: $error"], $error);
    }

    my $journal = do { open(my $fh, '<', $t->{journal}->path) or die "Cannot read: $!"; local $/; <$fh> };
    my $result  = $t->{sheet}->fill(partial($data, $id => {commit => $revision, path => 'lib/Foo.pm', lines => [3, 5]}));
    is($result->{filled}, 1, 'placed');
    is(
        $t->{db}->dbh->selectrow_hashref('SELECT note_id, path, line_start, line_end, color, color_reason, kind, sentence, detail, pending FROM flag'),
        {note_id => $t->{note}, path => 'lib/Foo.pm', line_start => 3, line_end => 5, color => 'red', color_reason => undef, kind => 'deviation', sentence => 'One changed.', detail => undef, pending => 0},
        'flag row',
    );
    is($t->{journal}->notes, [], 'note left the journal');
    ok(!items_by_id($t->{sheet}->sheet)->{$id}, 'no longer in the sheet');

    # A removal that failed after the commit leaves a placed note behind.
    {
        open(my $fh, '>', $t->{journal}->path) or die "Cannot write: $!";
        print $fh $journal;
    }
    is(scalar(@{$t->{journal}->notes}), 1, 'a placed note is back in the journal');
    my $again = $t->{sheet}->sheet;
    ok(!items_by_id($again)->{$id}, 'a note already a flag gets no item');
    $t->{sheet}->fill($again);
    is($t->{journal}->notes,                                                                             [], 'the next fill removes it');
    is($t->{db}->dbh->selectrow_array('SELECT COUNT(*) FROM flag WHERE note_id = ?', undef, $t->{note}), 1,  'placed once');

    my $fyi = $t->{journal}->add(path => 'style.scss', sentence => 'Just so you know.');
    ok(!items_by_id($t->{sheet}->sheet)->{"note:$fyi"}, 'a note without a flag, a journal entry, gets no item');
    $t->{sheet}->fill($t->{sheet}->sheet);
    is([map { $_->{id} } @{$t->{journal}->notes}], [$fyi], 'and a fill leaves it in the journal for the next build or iteration');
    $t->{journal}->remove($fyi);

    my $whole = $t->{journal}->add(flag => 'yellow', kind => 'note', path => 'style.scss', sentence => 'Whole commit.');
    $t->{sheet}->fill(partial($t->{sheet}->sheet, "note:$whole" => {commit => $revision}));
    is($t->{db}->dbh->selectrow_hashref('SELECT path, line_start FROM flag WHERE note_id = ?', undef, $whole), {path => undef, line_start => undef}, 'whole-commit flag');

    my $del = commit_file($t->{dir}, 'Drop keep', 'keep.txt' => undef);
    Review::Helper::Builder->new(repo => $t->{repo}, db => $t->{db})->iterate;
    my $gone = $t->{journal}->add(flag => 'yellow', kind => 'note', path => 'keep.txt', sentence => 'Removed.');
    $id   = "note:$gone";
    $data = $t->{sheet}->sheet;
    is(errors_of($t->{sheet}, partial($data, $id => {commit => $del, path => 'keep.txt', lines => [2, 4]})), ["$id: 'lines': beyond the end of 'keep.txt' (3 lines)"], 'a deleted file is checked on its old side');
    $t->{sheet}->fill(partial($data, $id => {commit => $del, path => 'keep.txt', lines => [2, 3]}));
    is($t->{db}->dbh->selectrow_hashref('SELECT path, line_start, line_end FROM flag WHERE note_id = ?', undef, $gone), {path => 'keep.txt', line_start => 2, line_end => 3}, 'placed on lines of a deleted file');
};

subtest flags => sub {
    my $t    = setup();
    my $data = $t->{sheet}->sheet;
    $t->{sheet}->fill(partial($data, "note:$t->{note}" => {commit => $t->{revision}, path => 'lib/Foo.pm', lines => [3, 5]}));
    my $whole = $t->{journal}->add(flag => 'yellow', kind => 'note', path => 'style.scss', sentence => 'Whole commit.', detail => 'More.');
    $t->{sheet}->fill(partial($t->{sheet}->sheet, "note:$whole" => {commit => $t->{revision}}));

    my $dbh = $t->{db}->dbh;
    my %ids = map { @$_ } @{$dbh->selectall_arrayref('SELECT note_id, id FROM flag')};
    my ($id, $other) = ("flag:$ids{$t->{note}}", "flag:$ids{$whole}");

    ok(!grep({ $_->{type} eq 'flag' } @{$t->{sheet}->sheet->{items}}), 'a flag that is not pending needs nothing: not in the default sheet');
    my $items = items_by_id($t->{sheet}->sheet(all => 1));
    is(
        $items->{$id}->{about},
        {note => $t->{note}, commit => $t->{revision}, topic => undef, path => 'lib/Foo.pm', lines => [3, 5], color => 'red', color_reason => undef, kind => 'deviation', sentence => 'One changed.', detail => undef, pending => F(), left_change => F(), rewritten => F(), previous => undef},
        'flag about',
    );
    is($items->{$other}->{about}, hash { field path => undef; field lines => undef; field color => 'yellow'; field kind => 'note'; field detail => 'More.'; etc() }, 'whole-commit flag about');
    is($items->{$id}->{fields},   {decision => undef, color => undef, reason => undef},                                                                              'its fields are actions, always null');
    ok(!exists $items->{$id}->{optional}, 'not marked optional');

    # A second iteration over the same commit, its flags made pending as the
    # builder makes a flag carried onto changed code.
    Review::Helper::Builder->new(repo => $t->{repo}, db => $t->{db})->iterate;
    my %new = map { @$_ } @{$dbh->selectall_arrayref('SELECT f.note_id, f.id FROM flag f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = 2')};
    ($id, $other) = ("flag:$new{$t->{note}}", "flag:$new{$whole}");
    $dbh->do(q{UPDATE flag SET pending = 1, line_start = 4, line_end = 6 WHERE id = ?}, undef, $new{$t->{note}});
    $dbh->do(q{UPDATE flag SET pending = 1 WHERE id = ?},                               undef, $new{$whole});

    $data  = $t->{sheet}->sheet;
    $items = items_by_id($data);
    is($items->{$id}->{about}->{previous},             {commit => $t->{revision}, path => 'lib/Foo.pm', lines => [3, 5]}, 'a pending flag gives where it was in the previous iteration');
    is([@{$items->{$id}->{about}}{qw/pending lines/}], [T(), [4, 6]],                                                     'and where it is now');
    ok(!exists $items->{$id}->{optional}, 'a pending flag needs a decision');
    is([sort grep { /^flag:/ } keys %$items], [sort $id, $other], 'both pending flags are listed in the default sheet');

    my %bad = (
        "$id: 'decision' must be 'keep', 'recolor' or 'retire'"           => {color    => 'yellow'},
        "$id: unknown field 'lines'"                                      => {decision => 'keep',    lines => [1, 1]},
        "$id: 'color' must be 'yellow' or 'red'"                          => {decision => 'recolor', color => 'green', reason => 'Worse.'},
        "$id: 'reason' must be a non-empty string: why the color changed" => {decision => 'recolor', color => 'yellow'},
        "$id: 'color' is the flag's color already; use 'keep'"            => {decision => 'recolor', color => 'red', reason => 'Same.'},
    );
    for my $want (sort keys %bad) {
        my ($which) = $want =~ m/^(flag:\d+)/;
        is(errors_of($t->{sheet}, partial($data, $which => $bad{$want})), [$want], "rejected: $want");
    }

    # Keep: settled where the carry put it.
    $t->{sheet}->fill(partial($data, $id => {decision => 'keep', color => 'yellow', reason => 'Ignored.'}, $other => {decision => 'keep', color => undef, reason => undef}));
    is($dbh->selectrow_hashref('SELECT pending, line_start, line_end, color FROM flag WHERE id = ?', undef, $new{$t->{note}}), {pending => 0, line_start => 4, line_end => 6, color => 'red'}, 'keep settles it, on the lines the carry gave it');
    is($dbh->selectrow_hashref('SELECT pending, line_start FROM flag WHERE id = ?', undef, $new{$whole}), {pending => 0, line_start => undef}, 'a whole-commit flag too');
    ok(!grep({ $_->{type} eq 'flag' } @{$t->{sheet}->sheet->{items}}), 'nothing pending left');

    # Recolor: to yellow keeps the seen marks; yellow to red makes the flag
    # unseen again.
    $t->{db}->set_flag_seen($new{$t->{note}}, 'Ann', 1);
    $t->{sheet}->fill(partial($t->{sheet}->sheet(all => 1), $id => {decision => 'recolor', color => 'yellow', reason => 'Fixed in the next commit.'}));
    is(
        $dbh->selectrow_hashref('SELECT color, color_reason, (SELECT count(*) FROM flag_seen WHERE flag = flag.id) AS seen FROM flag WHERE id = ?', undef, $new{$t->{note}}),
        {color => 'yellow', color_reason => 'Fixed in the next commit.', seen => 1},
        'turned yellow, it keeps the seen marks',
    );
    $t->{sheet}->fill(partial($t->{sheet}->sheet(all => 1), $id => {decision => 'recolor', color => 'red', reason => 'The fix broke it.'}));
    is(
        $dbh->selectrow_hashref('SELECT color, color_reason, (SELECT count(*) FROM flag_seen WHERE flag = flag.id) AS seen FROM flag WHERE id = ?', undef, $new{$t->{note}}),
        {color => 'red', color_reason => 'The fix broke it.', seen => 0},
        'turned red, it is unseen by everyone',
    );

    # Retire: its feedback moves to its file, or its commit, keeping the flag.
    $t->{db}->add_feedback(iteration => 1, target => 'flag', revision => $t->{revision}, path => 'lib/Foo.pm', flag => $t->{note}, flag_sentence => 'One changed.', body => 'Why?');
    $t->{db}->add_feedback(iteration => 2, target => 'flag', revision => $t->{revision}, flag => $whole, flag_sentence => 'Whole commit.', body => 'And this?');
    is(items_by_id($t->{sheet}->sheet)->{'feedback:1'}->{about}, hash { field target => 'flag'; field flag => {note => $t->{note}, sentence => 'One changed.', path => 'lib/Foo.pm', lines => [3, 5]}; etc() }, 'feedback on a flag names it, with its sentence and its lines in that iteration');
    $t->{db}->set_flag_seen($new{$t->{note}}, 'Ann', 1);
    my $step = {target => {type => 'flag', flag => $t->{note}}, highlight => [], commentary => 'The flag.'};
    $data = $t->{sheet}->sheet(all => 1);
    is(errors_of($t->{sheet}, partial($data, $id => {decision => 'retire'}, 'guide:2' => {steps => [$step]})), ["guide:2: step 1: target: flag '$t->{note}' is retired in this sheet"], 'a guide may not name a flag the same sheet retires');

    $t->{sheet}->fill(partial($data, 'guide:2' => {steps => [$step]}));
    ok(!items_by_id($t->{sheet}->sheet)->{'guide:2'}, 'the guide is done');
    $t->{sheet}->fill(partial($t->{sheet}->sheet(all => 1), $id => {decision => 'retire'}, $other => {decision => 'retire'}));
    is($dbh->selectall_arrayref('SELECT f.note_id FROM flag f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = 2'), [],                                                              'retired flags leave the iteration');
    is($dbh->selectrow_array('SELECT count(*) FROM flag f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = 1'),     2,                                                               'earlier iterations keep them');
    is($dbh->selectrow_array('SELECT count(*) FROM flag_seen WHERE flag = ?', undef, $new{$t->{note}}),                          0,                                                               'with their seen marks');
    is($dbh->selectall_arrayref('SELECT target, path, flag FROM feedback ORDER BY id'),                                          [['file', 'lib/Foo.pm', $t->{note}], ['commit', undef, $whole]], 'their feedback moves to the file, or the commit, keeping the flag');
    ok(items_by_id($t->{sheet}->sheet)->{'guide:2'}, 'a guide naming a retired flag is asked for again');
};

# A flag with no copy in another iteration: retiring it deletes its only
# row, and its feedback still says which flag it was on.
subtest retire_only_copy => sub {
    my $t     = setup();
    my $dbh   = $t->{db}->dbh;
    my $whole = $t->{journal}->add(flag => 'yellow', path => 'style.scss', sentence => 'Whole commit.');
    $t->{sheet}->fill(partial($t->{sheet}->sheet, "note:$t->{note}" => {commit => $t->{revision}, path => 'lib/Foo.pm', lines => [3, 5]}));
    my %ids = map { @$_ } @{$dbh->selectall_arrayref('SELECT note_id, id FROM flag')};
    $t->{db}->add_feedback(iteration => 1, target => 'flag', revision => $t->{revision}, path => 'lib/Foo.pm', flag => $t->{note}, flag_sentence => 'One changed.', body => 'Why?');

    # Placed and retired in the same iteration, from one sheet each.
    $t->{sheet}->fill(partial($t->{sheet}->sheet, "note:$whole" => {commit => $t->{revision}}));
    my ($whole_id) = $dbh->selectrow_array('SELECT id FROM flag WHERE note_id = ?', undef, $whole);
    $t->{db}->add_feedback(iteration => 1, target => 'flag', revision => $t->{revision}, flag => $whole, flag_sentence => 'Whole commit.', body => 'And this?');

    $t->{sheet}->fill(partial($t->{sheet}->sheet(all => 1), "flag:$ids{$t->{note}}" => {decision => 'retire'}, "flag:$whole_id" => {decision => 'retire'}));
    is($dbh->selectrow_array('SELECT COUNT(*) FROM flag'), 0, 'no flag row is left in any iteration');
    is(
        [map { [$_->{target}, $_->{flag}] } @{Review::Helper::Feedback->new(db => $t->{db})->export->{feedback}}],
        [['file', {note => $t->{note}, sentence => 'One changed.', path => 'lib/Foo.pm', lines => undef}], ['commit', {note => $whole, sentence => 'Whole commit.', path => undef, lines => undef}]],
        'the export still gives the sentence of the flag each was on',
    );
};

subtest feedback_and_debate => sub {
    my $t   = setup();
    my $dbh = $t->{db}->dbh;
    $dbh->do(q{INSERT INTO feedback (iteration, target, revision, path, section_name, section_package, body, created, updated, status) VALUES (1, 'section', ?, 'lib/Foo.pm', 'one', 'Foo', 'Why?', 1, 1, 'open')}, undef, $t->{revision});
    $dbh->do(q{INSERT INTO feedback (iteration, target, body, created, updated, status) VALUES (1, 'review', 'Hm.', 1, 1, 'open')});
    $dbh->do(q{INSERT INTO request (iteration, kind, target, note, status, created) VALUES (1, 'debate', 'review', 'Sure?', 'open', 1)});

    my $data  = $t->{sheet}->sheet;
    my $items = items_by_id($data);
    is($items->{'feedback:1'}->{about}, {target => 'section', commit => $t->{revision}, topic => undef, path => 'lib/Foo.pm', section => {name => 'one', package => 'Foo'}, flag => undef, iteration => 1, line => undef, side => undef, body => 'Why?'}, 'feedback about');
    is($items->{'request:1'}->{about}, {target => 'review', commit => undef, topic => undef, path => undef, section => undef, iteration => 1, note => 'Sure?'}, 'debate about');

    is(errors_of($t->{sheet}, partial($data, 'feedback:1' => {status => 'open'})), ["feedback:1: 'status' must be 'addressed' or 'declined'", "feedback:1: 'status' needs a 'response'"], 'status checked');

    $t->{sheet}->fill(partial($data, 'feedback:1' => {status => 'addressed', response => 'Done.'}, 'feedback:2' => {status => 'declined', response => 'No.'}, 'request:1' => {case_for => 'Yes.'}));
    is($dbh->selectall_arrayref('SELECT status, response, resolved_in FROM feedback ORDER BY id'), [['addressed', 'Done.', 1], ['declined', 'No.', undef]], 'feedback written');
    is($dbh->selectrow_hashref('SELECT status, case_for FROM request'),                            {status => 'open', case_for => 'Yes.'},                  'one case leaves the debate open');

    $t->{sheet}->fill(partial($t->{sheet}->sheet, 'request:1' => {case_against => 'No.'}));
    is($dbh->selectrow_hashref('SELECT status, case_for, case_against FROM request'), {status => 'done', case_for => 'Yes.', case_against => 'No.'}, 'both cases finish it');
    is([grep { /^(?:feedback|request):/ } keys %{items_by_id($t->{sheet}->sheet)}],   [],                                                            'nothing open left');
};

subtest all => sub {
    my $t           = setup();
    my $dbh         = $t->{db}->dbh;
    my ($commit_id) = $dbh->selectrow_array('SELECT id FROM commit_entry');
    my $revision    = $t->{revision};
    $dbh->do(q{INSERT INTO request (iteration, kind, target, note, status, created) VALUES (1, 'debate', 'review', 'Sure?', 'open', 1)});

    my $step = {target => {type => 'commit', commit => $revision}, highlight => [], commentary => 'First words.'};
    $t->{sheet}->fill(partial(
        $t->{sheet}->sheet,
        "commit:$commit_id" => {what     => 'CW', why => 'CY', how => 'CH'},
        "note:$t->{note}"   => {commit   => $revision},
        'request:1'         => {case_for => 'For.', case_against => 'Against.'},
        'guide:1'           => {steps    => [$step]},
    ));
    my ($flag_id) = $dbh->selectrow_array('SELECT id FROM flag');

    my @splits  = map { "split:$_" } @{$dbh->selectcol_arrayref('SELECT id FROM file_change ORDER BY path')};
    my @done    = ("commit:$commit_id", @splits, "flag:$flag_id", 'request:1', 'guide:1');
    my $default = $t->{sheet}->sheet;
    my $all     = $t->{sheet}->sheet(all => 1);
    my $items   = items_by_id($all);
    ok(!items_by_id($default)->{$_}, "$_ not in the default sheet") for @done;
    is([grep { !items_by_id($default)->{$_->{id}} } @{$all->{items}}], [map { $items->{$_} } @done],                                                    'all adds only the done items');
    is($default,                                                       {%$all, items => [grep { items_by_id($default)->{$_->{id}} } @{$all->{items}}]}, 'the default sheet is the rest, unchanged');

    is($items->{"commit:$commit_id"}->{fields}, {what => 'CW', why => 'CY', how => 'CH'},             'commit with its text');
    is($items->{"flag:$flag_id"}->{fields},     {decision => undef, color => undef, reason => undef}, 'a flag, its fields null');
    is($items->{'request:1'}->{fields},         {case_for => 'For.', case_against => 'Against.'},     'finished debate with its cases');
    is($items->{'guide:1'}->{fields},           {steps => [$step]},                                   'guide with its steps');
    ok(!grep({ $_->{type} eq 'note' } @{$all->{items}}), 'a placed note does not come back');

    is(
        errors_of($t->{sheet}, partial($all, 'guide:1' => {steps => [{%$step, commentary => 'Calls run().'}]}, "flag:$flag_id" => {decision => 'drop'})),
        ["flag:$flag_id: 'decision' must be 'keep', 'recolor' or 'retire'", "guide:1: step 1: 'commentary' must be read aloud: no backticks, '->', '::', '()', or a sigil before a word"],
        'a replacement is validated like a first fill',
    );

    my $result = $t->{sheet}->fill(partial(
        $all,
        "commit:$commit_id" => {what     => 'Sharper.'},
        "flag:$flag_id"     => {decision => 'recolor', color => 'yellow', reason => 'Less than feared.'},
        'request:1'         => {case_for => 'For, sharper.'},
        'guide:1'           => {steps    => [{%$step, commentary => 'Better words.'}]},
    ));
    is($result->{filled},                                                             4,                                                                           'filled from the all sheet');
    is($dbh->selectrow_hashref('SELECT what, why FROM commit_entry'),                 {what => 'Sharper.', why => 'CY'},                                           'text replaced, other fields kept');
    is($dbh->selectrow_hashref('SELECT color, color_reason FROM flag'),               {color => 'yellow', color_reason => 'Less than feared.'},                    'flag recolored');
    is($dbh->selectrow_hashref('SELECT status, case_for, case_against FROM request'), {status => 'done', case_for => 'For, sharper.', case_against => 'Against.'}, 'debate case replaced, still done');
    is($dbh->selectall_arrayref('SELECT commentary FROM guide_step'),                 [['Better words.']],                                                         'guide replaced');

    is(
        errors_of($t->{sheet}, partial($all, "commit:$commit_id" => {what => 'Stale.'})),
        ["commit:$commit_id: stale revision; get a new sheet"],
        'a rev from before another fill is rejected',
    );
    is($dbh->selectrow_array('SELECT what FROM commit_entry'), 'Sharper.', 'nothing overwritten');
};

subtest splits => sub {
    my $t     = setup(split => 0);
    my $dbh   = $t->{db}->dbh;
    my ($css) = $dbh->selectrow_array(q{SELECT id FROM file_change WHERE path = 'style.scss'});
    my ($foo) = $dbh->selectrow_array(q{SELECT id FROM file_change WHERE path = 'lib/Foo.pm'});
    my $data  = $t->{sheet}->sheet;
    my $id    = "split:$css";

    is(
        items_by_id($data)->{$id},
        {
            id     => $id,
            type   => 'split',
            rev    => T(),
            about  => {commit   => $t->{revision}, path => 'style.scss', old_path => undef, status => 'M', kind => 'text', size_before => 8, size_after => 8, request => undef, sections => [], previous => undef},
            fields => {sections => undef},
        },
        'a required split item for each changed text file, with its changed lines',
    );
    ok(!(grep { $_->{type} eq 'section' } @{$data->{items}}), 'no section items before the split');

    my $a1    = 'a1 { color: red; }';
    my $a2    = 'a2 { color: blue; }';
    my $a3    = 'a3 { color: red; }';
    my $nm    = "'name' must be a non-empty string";
    my %cases = (
        "'sections' must be an array"                                                                  => {},
        'section 1: must be an object'                                                                 => ['x'],
        "section 1: $nm"                                                                               => [{name => '  ', lines => [[1, 1]], first_line => $a1}],
        "section 1: $nm."                                                                              => [{name => [], lines => [[1, 1]], first_line => $a1}],
        "section 1: 'package' must be a non-empty string or null"                                      => [{name => 'a', package => ' ', lines => [[1, 1]], first_line => $a1}],
        "section 1: unknown field 'ranges'"                                                            => [{name => 'a', ranges => [[1, 1]], lines => [[1, 1]], first_line => $a1}],
        "section 1: 'lines' must be an array of [start, end] ranges"                                   => [{name => 'a', lines => [1, 1]}],
        "section 1: 'lines' or 'old_lines' must hold a range"                                          => [{name => 'a'}],
        "section 1: 'doc_lines' needs 'lines'"                                                         => [{name => 'a', doc_lines => [[1, 1]], old_lines => [[2, 2]], old_first_line => $a2}],
        "section 1: 'first_line' needs 'lines'"                                                        => [{name => 'a', old_lines => [[2, 2]], old_first_line => 'a2 { color: red; }', first_line => $a2}],
        "section 1: 'old_first_line' needs 'old_lines'"                                                => [{name => 'a', lines => [[1, 1]], first_line => $a1, old_first_line => $a1}],
        "section 1: new range [9,9]: beyond the end of 'style.scss' (8 lines)"                         => [{name => 'a', lines => [[9, 9]], first_line => $a1}],
        'section 1: new range [2,1]: start is after end'                                               => [{name => 'a', lines => [[2, 1]], first_line => $a1}],
        'section 1: new range [0,1]: must be [start, end]'                                             => [{name => 'a', lines => [[0, 1]], first_line => $a1}],
        "section 1: old range [9,9]: beyond the end of 'style.scss' (8 lines)"                         => [{name => 'a', old_lines => [[9, 9]], old_first_line => $a1}],
        'section 2: new range [2,3]: overlaps section 1'                                               => [{name => 'a', lines => [[1, 2]], first_line => $a1}, {name => 'b', lines => [[2, 3]], first_line => $a2}],
        'section 2: new range [1,1]: overlaps section 1'                                               => [{name => 'a', lines => [[2, 2]], doc_lines => [[1, 1]], first_line => $a2}, {name => 'b', lines => [[1, 1]], first_line => $a1}],
        'section 1: new range [2,2]: overlaps itself'                                                  => [{name => 'a', lines => [[1, 2]], doc_lines => [[2, 2]], first_line => $a1}],
        'section 2: old range [2,2]: overlaps section 1'                                               => [{name => 'a', old_lines => [[2, 2]], old_first_line => 'a2 { color: red; }'}, {name => 'b', old_lines => [[2, 2]], old_first_line => 'a2 { color: red; }'}],
        "section 1: 'first_line' is required: the text of its first line"                              => [{name => 'a', lines     => [[1, 1]]}],
        "section 1: 'old_first_line' is required: the text of its first line"                          => [{name => 'a', old_lines => [[2, 2]]}],
        qq{section 1: 'first_line' does not match line 2, which reads "a2 { color: blue; }"}           => [{name => 'a', lines => [[3, 3], [2, 2]], first_line => $a3}],
        qq{section 1: 'old_first_line' does not match line 2, which reads "a2 { color: red; }"}        => [{name => 'a', old_lines => [[2, 2]], old_first_line => $a2}],
        "section 2: name 'a' repeats; make it unique, for example with ' (2)'"                         => [{name => 'a', lines => [[1, 1]], first_line => $a1}, {name => 'a', lines => [[2, 2]], first_line => $a2}],
        "section 2: name 'a' repeats; make it unique, for example with ' (2)'."                        => [{name => 'a', lines => [[1, 1]], first_line => $a1}, {name => "a \t", lines => [[2, 2]], first_line => $a2}],
        "section 2: name 'a' repeats in package 'P'; make it unique, for example with ' (2)'."         => [{name => 'a', package => 'P', lines => [[1, 1]], first_line => $a1}, {name => ' a', package => 'P ', lines => [[2, 2]], first_line => $a2}],
        "section 2: name 'a' repeats in package 'P'; make it unique, for example with ' (2)'"          => [{name => 'a', package => 'P', lines => [[1, 1]], first_line => $a1}, {name => 'a', package => 'P', old_lines => [[2, 2]], old_first_line => 'a2 { color: red; }'}],
        'lines 2-3, 5-8 are in no section; cover every line of the file, or give [] to leave it whole' => [{name => 'a', lines => [[1, 1], [4, 4]], first_line => $a1}],
    );
    for my $error (sort keys %cases) {
        is(errors_of($t->{sheet}, partial($data, $id => {sections => $cases{$error}})), ["$id: " . ($error =~ s/\.+\z//r)], $error);
    }
    is(
        errors_of($t->{sheet}, partial($data, $id => {sections => [{name => '', lines => [[1, 2]], first_line => $a1}, {name => 'b', lines => [[2, 2]], first_line => $a2}]})),
        ["$id: section 1: $nm", "$id: section 2: new range [2,2]: overlaps section 1"],
        'a section with a bad name still claims its lines',
    );

    $t->{sheet}->fill(partial(
        $data,
        $id          => {sections => [{name => ' a2', lines => [[2, 2]], first_line => "  $a2\t"}, {name => 'a1', lines => [[1, 1]], first_line => $a1}, {name => "a2\n", package => ' other ', lines => [[3, 3]], first_line => 'a3 { color: red; }'}, {name => 'rest', lines => [[4, 8]], first_line => 'a4 { color: red; }'}]},
        "split:$foo" => {sections => []},
    ));
    is(
        $dbh->selectall_arrayref('SELECT position, name, ranges, doc_ranges, changed, what FROM section WHERE file_id = ?', undef, $css),
        [[1, 'a1', '[[1,1]]', '[]', 0, undef], [2, 'a2', '[[2,2]]', '[]', 1, undef], [3, 'a2', '[[3,3]]', '[]', 0, undef], [4, 'rest', '[[4,8]]', '[]', 0, undef]],
        'the agent units in file order, whitespace around a first line ignored and around names and packages trimmed, a name repeated in another package allowed; untouched units kept',
    );
    is(
        $dbh->selectall_arrayref('SELECT name, ranges, changed FROM section WHERE file_id = ?', undef, $foo),
        [],
        'a file left whole has no sections',
    );
    is($dbh->selectall_arrayref('SELECT DISTINCT split_source FROM file_change WHERE id IN (?, ?)', undef, $css, $foo), [['agent']], 'labeled agent');
    ok(!items_by_id($t->{sheet}->sheet)->{$id}, 'the split is done');
    like(items_by_id($t->{sheet}->sheet(all => 1))->{$id}, {fields => {sections => undef}, about => {sections => [map { {name => $_->[0], package => $_->[1], lines => [$_->[2]], doc_lines => []} } ['a1', undef, [1, 1]], ['a2', undef, [2, 2]], ['a2', 'other', [3, 3]], ['rest', undef, [4, 8]]]}}, 'listed with all: its whole stored split in about');
    is([map { $_->{about}->{name} } grep { $_->{type} eq 'section' && $_->{about}->{path} eq 'style.scss' } @{$t->{sheet}->sheet(all => 1)->{items}}], ['a2'], 'only the section the commit changed is explained');

    $dbh->do(q{INSERT INTO request (iteration, kind, target, revision, path, note, status, created) VALUES (1, 'split', 'file', ?, 'lib/Foo.pm', 'Split it.', 'open', 1)}, undef, $t->{revision});
    $data = $t->{sheet}->sheet;
    my $req = items_by_id($data)->{"split:$foo"};
    is([$req->{optional}, $req->{about}->{request}], [undef, {id => 1, note => 'Split it.'}], 'a requested split is required again');

    my %two  = (name => 'sub two', package => 'Foo', lines => [[7,  9]],  first_line => 'sub two {');
    my %head = (name => 'header',  package => 'Foo', lines => [[1,  1]],  first_line => 'package Foo;');
    my %end  = (name => 'end',     package => 'Foo', lines => [[11, 11]], first_line => '1;');
    $t->{sheet}->fill(partial($data, "split:$foo" => {sections => [\%head, {name => 'sub one', package => 'Foo', lines => [[3, 5]], first_line => 'sub one {'}, \%two, \%end]}));
    is($dbh->selectall_arrayref('SELECT name, ranges FROM section WHERE file_id = ? ORDER BY position', undef, $foo), [['header', '[[1,2]]'], ['sub one', '[[3,6]]'], ['sub two', '[[7,10]]'], ['end', '[[11,11]]']], 'the split replaces the sections; blank lines join the section before them');
    is($dbh->selectrow_array('SELECT status FROM request'),                                                           'done',                                                                                         'request done');

    $dbh->do(q{UPDATE section SET what = 'old ' || name WHERE file_id = ?},                                                                             undef, $foo);
    $dbh->do(q{INSERT INTO request (iteration, kind, target, revision, path, status, created) VALUES (1, 'split', 'file', ?, 'lib/Foo.pm', 'open', 1)}, undef, $t->{revision});
    $data = $t->{sheet}->sheet;
    ok(!items_by_id($data)->{"split:$foo"}->{optional}, 'a second split request asks for a split again');
    $t->{sheet}->fill(partial($data, "split:$foo" => {sections => [\%head, {name => 'sub one', package => 'Foo', lines => [[3, 4]], first_line => 'sub one {'}, {%end, name => 'sub one: end', lines => [[5, 5]], first_line => '}'}, \%two, \%end]}));
    is(
        $dbh->selectall_arrayref('SELECT name, ranges, what FROM section WHERE file_id = ? ORDER BY position', undef, $foo),
        [['header', '[[1,2]]', undef], ['sub one', '[[3,4]]', undef], ['sub one: end', '[[5,6]]', undef], ['sub two', '[[7,10]]', undef], ['end', '[[11,11]]', undef]],
        'a re-split is explained afresh: no section keeps its text, not even one that reads the same',
    );
    is($dbh->selectall_arrayref('SELECT status FROM request ORDER BY id'), [['done'], ['done']], 'that request done too');

    # A later commit drops sub two and deletes keep.txt.
    my $drop = commit_file($t->{dir}, 'Drop two', 'lib/Foo.pm' => "package Foo;\n\nsub one {\n    return 10;\n}\n\n1;\n", 'keep.txt' => undef);
    Review::Helper::Builder->new(repo => $t->{repo}, db => $t->{db})->iterate;
    my ($foo2) = $dbh->selectrow_array(q{SELECT f.id FROM file_change f JOIN commit_entry c ON c.id = f.commit_id WHERE c.revision = ? AND f.path = 'lib/Foo.pm'}, undef, $drop);
    my ($keep) = $dbh->selectrow_array(q{SELECT f.id FROM file_change f JOIN commit_entry c ON c.id = f.commit_id WHERE c.revision = ? AND f.path = 'keep.txt'},   undef, $drop);
    $dbh->do(q{INSERT INTO request (iteration, kind, target, revision, path, status, created) VALUES (2, 'split', 'file', ?, 'keep.txt', 'open', 1)}, undef, $drop);

    $data = items_by_id($t->{sheet}->sheet);
    ok(!$data->{"split:$keep"}, 'no split item for a deleted file, even when requested');
    is(
        $data->{"split:$foo2"}->{about}->{previous},
        {
            commit    => $t->{revision},
            iteration => 1,
            path      => 'lib/Foo.pm',
            sections  => [
                {name => 'header',       package => 'Foo', lines => [[1,  2]],  doc_lines => []},
                {name => 'sub one',      package => 'Foo', lines => [[3,  4]],  doc_lines => []},
                {name => 'sub one: end', package => 'Foo', lines => [[5,  6]],  doc_lines => []},
                {name => 'sub two',      package => 'Foo', lines => [[7,  10]], doc_lines => []},
                {name => 'end',          package => 'Foo', lines => [[11, 11]], doc_lines => []},
            ],
        },
        'the whole split an earlier iteration stored, its lines as they were at that commit',
    );
    unlike($JSON->encode($data->{"split:$foo2"}->{about}->{previous}), qr/"[0-9]+"/, 'line numbers are JSON numbers');

    my $gone = {name => 'sub two', package => 'Foo', old_lines => [[7, 10]], old_first_line => 'sub two {'};
    my @rest = (\%head, {name => 'sub one', package => 'Foo', lines => [[3, 5]], first_line => 'sub one {'}, {%end, lines => [[7, 7]]});
    $t->{sheet}->fill(partial($t->{sheet}->sheet, "split:$foo2" => {sections => [@rest, $gone]}));
    my $deleted = sub { $dbh->selectall_arrayref('SELECT name, ranges, old_ranges, deleted, removed, what FROM section WHERE file_id = ? AND deleted = 1', {Slice => {}}, $foo2) };
    is($deleted->(), [{name => 'sub two', ranges => '[]', old_ranges => '[[7,10]]', deleted => 1, removed => 4, what => undef}], 'a unit with only old lines is a deleted section owning its removed lines');

    $dbh->do(q{UPDATE section SET what = 'gone' WHERE file_id = ? AND deleted = 1}, undef, $foo2);
    $t->{sheet}->fill(partial($t->{sheet}->sheet(all => 1), "split:$foo2" => {sections => [@rest, $gone]}));
    is($deleted->()->[0]->{what}, undef, 'a re-split explains the deleted unit afresh too');
};

subtest resplit_feedback => sub {
    my $dir      = make_repo();
    my $base     = commit_file($dir, 'Base',   'lib/Foo.pm' => "package Foo;\nuse v5.34;\n\nsub one {\n}\n\nour \$A = 0;\n\nsub two {\n}\n\nour \$B = 0;\n");
    my $revision = commit_file($dir, 'Change', 'lib/Foo.pm' => "package Foo;\nuse v5.36;\n\nsub one {\n}\n\nour \$A = 1;\n\nsub two {\n}\n\nour \$B = 1;\n\n1;\n");
    my $repo     = Review::Helper::VCS->detect($dir);
    my $db       = Review::Helper::DB->open(Review::Helper::Builder->new(repo => $repo)->build(base => $base));
    my $sheet    = $CLASS->new(repo => $repo, db => $db);
    my $dbh      = $db->dbh;
    my ($foo)    = $dbh->selectrow_array(q{SELECT id FROM file_change WHERE path = 'lib/Foo.pm'});
    my $rows     = sub { $dbh->selectall_arrayref('SELECT name, ranges, what FROM section WHERE file_id = ? ORDER BY position', undef, $foo) };
    my %unit     = (
        header  => {name => 'header',  lines => [[1,  2]]},
        one     => {name => 'sub one', lines => [[4,  5]]},
        A       => {name => 'our $A',  lines => [[7,  7]]},
        two     => {name => 'sub two', lines => [[9,  10]]},
        B       => {name => 'our $B',  lines => [[12, 14]]},
        globals => {name => 'globals', lines => [[7,  7]]},
    );
    $_->{package} = 'Foo' for values %unit;

    fill_splits($repo, $db, sub ($about) { [@unit{qw/header one A two B/}] });
    is(
        $rows->(),
        [['header', '[[1,3]]', undef], ['sub one', '[[4,6]]', undef], ['our $A', '[[7,8]]', undef], ['sub two', '[[9,11]]', undef], ['our $B', '[[12,14]]', undef]],
        'every section is kept',
    );
    $dbh->do(q{UPDATE section SET what = 'old ' || name WHERE file_id = ?}, undef, $foo);

    my %fb     = map { ($_ => $db->add_feedback(iteration => 1, target => 'section', revision => $revision, path => 'lib/Foo.pm', section_name => $_,       section_package => 'Foo', body => "On $_.")) } 'our $A',       'our $B';
    my %closed = map { ($_ => $db->add_feedback(iteration => 1, target => 'section', revision => $revision, path => 'lib/Foo.pm', section_name => 'our $A', section_package => 'Foo', body => "Closed $_.")) } 'declined', 'published';
    $dbh->do(q{UPDATE feedback SET status = 'declined', response = 'No.' WHERE id = ?},                       undef, $closed{declined});
    $dbh->do(q{UPDATE feedback SET status = 'addressed', response = 'Fixed it.', published = 5 WHERE id = ?}, undef, $closed{published});

    my $debate = $dbh->prepare(q{INSERT INTO request (iteration, kind, target, revision, path, section_name, section_package, note, status, created) VALUES (1, 'debate', 'section', ?, 'lib/Foo.pm', ?, 'Foo', ?, 'open', 1)});
    $debate->execute($revision, $_, "Why $_?") for 'our $A', 'our $B';

    # The agent renames one section.
    $dbh->do(q{INSERT INTO request (iteration, kind, target, revision, path, status, created) VALUES (1, 'split', 'file', ?, 'lib/Foo.pm', 'open', 1)}, undef, $revision);
    fill_splits($repo, $db, sub ($about) { [@unit{qw/header one globals two B/}] });
    is(
        $rows->(),
        [['header', '[[1,3]]', undef], ['sub one', '[[4,6]]', undef], ['globals', '[[7,8]]', undef], ['sub two', '[[9,11]]', undef], ['our $B', '[[12,14]]', undef]],
        'the re-split sections start with no explanation',
    );

    is(
        $dbh->selectall_arrayref('SELECT target, section_name, section_package, body, status, response, published FROM feedback ORDER BY id', {Slice => {}}),
        [
            {target => 'file',    section_name => 'our $A', section_package => 'Foo', body => 'On our $A.',        status => 'open',      response => undef,       published => undef},
            {target => 'section', section_name => 'our $B', section_package => 'Foo', body => 'On our $B.',        status => 'open',      response => undef,       published => undef},
            {target => 'file',    section_name => 'our $A', section_package => 'Foo', body => 'Closed declined.',  status => 'declined',  response => 'No.',       published => undef},
            {target => 'file',    section_name => 'our $A', section_package => 'Foo', body => 'Closed published.', status => 'addressed', response => 'Fixed it.', published => 5},
        ],
        'feedback on a section split away moves to the file, keeping the section it was on and nothing else changed; the rest stays',
    );
    is(
        $dbh->selectall_arrayref(q{SELECT target, section_name, note, status FROM request WHERE kind = 'debate' ORDER BY id}, {Slice => {}}),
        [
            {target => 'file',    section_name => 'our $A', note => 'Why our $A?', status => 'open'},
            {target => 'section', section_name => 'our $B', note => 'Why our $B?', status => 'open'},
        ],
        'a debate on a section split away moves to the file the same way',
    );

    my $moved = "feedback:$fb{'our $A'}";
    is(items_by_id($sheet->sheet)->{$moved}->{about},                                {target => 'file', commit => $revision, topic => undef, path => 'lib/Foo.pm', section => {name => 'our $A', package => 'Foo'}, flag => undef, iteration => 1, line => undef, side => undef, body => 'On our $A.'}, 'the sheet shows the section it was on');
    is(errors_of($sheet, partial($sheet->sheet, $moved => {status => 'addressed'})), ["$moved: 'status' needs a 'response'"],                                                                                                                                                                           'it needs a response like any feedback');
    $sheet->fill(partial($sheet->sheet, $moved => {status => 'addressed', response => 'Fixed it.'}));
    is($dbh->selectrow_hashref('SELECT status, response FROM feedback WHERE id = ?', undef, $fb{'our $A'}), {status => 'addressed', response => 'Fixed it.'}, 'the response is the agent\'s alone');

    # Asked again: 'our $B' survives, but on lines the commit did not change.
    $dbh->do(q{INSERT INTO request (iteration, kind, target, revision, path, status, created) VALUES (1, 'split', 'file', ?, 'lib/Foo.pm', 'open', 1)}, undef, $revision);
    fill_splits($repo, $db, sub ($about) { [@unit{qw/header one globals/}, {name => 'our $B', package => 'Foo', lines => [[9, 10]]}, {name => 'tail', package => 'Foo', lines => [[12, 14]]}] });
    is(
        $dbh->selectrow_hashref(q{SELECT changed, added, removed FROM section WHERE file_id = ? AND name = 'our $B'}, undef, $foo),
        {changed => 0, added => 0, removed => 0},
        'the section is kept, untouched',
    );
    is($dbh->selectrow_array('SELECT target FROM feedback WHERE id = ?', undef, $fb{'our $B'}),             'file', 'feedback on a section left untouched moves to the file, which the page shows');
    is($dbh->selectrow_array(q{SELECT target FROM request WHERE kind = 'debate' AND note = 'Why our $B?'}), 'file', 'so does a debate on it');
};

subtest previous_split => sub {
    my $dir   = make_repo();
    my @lines = map { "line $_\n" } 1 .. 20;
    my $text  = sub (%set) {
        join '' => map { $set{$_} // $lines[$_ - 1] } 1 .. 20;
    };
    my $base = commit_file($dir, 'Base', 'f.txt' => $text->());
    my $one  = commit_file($dir, 'One',  'f.txt' => $text->(2 => "two\n"));
    commit_file($dir, 'Two', 'f.txt' => $text->(2 => "two\n", 18 => "eighteen\n"));
    my $repo = Review::Helper::VCS->detect($dir);
    my $db   = Review::Helper::DB->open(Review::Helper::Builder->new(repo => $repo)->build(base => $base));
    my %by   = (One => [{name => 'top', lines => [[1, 5]]}, {name => 'rest', lines => [[6, 20]]}], Two => [{name => 'start', lines => [[1, 15]]}, {name => 'bottom', lines => [[16, 20]]}]);
    my $subj = sub ($revision) { $db->dbh->selectrow_array('SELECT subject FROM commit_entry WHERE revision = ?', undef, $revision) };
    fill_splits($repo, $db, sub ($about) { $by{$subj->($about->{commit})} });

    # Rebased onto a change in the middle of the file: One keeps its change id
    # but not its file, so it needs a split again.
    run_git($dir, qw/reset -q --hard/, $base);
    commit_file($dir, 'Middle', 'f.txt' => $text->(10 => "ten\n"));
    my $one2 = commit_file($dir, 'One', 'f.txt' => $text->(2 => "two\n", 10 => "ten\n"));
    Review::Helper::Builder->new(repo => $repo, db => $db)->iterate;

    my ($item) = grep { $_->{type} eq 'split' && $_->{about}->{commit} eq $one2 } @{$CLASS->new(repo => $repo, db => $db)->sheet->{items}};
    is(
        $item->{about}->{previous},
        {
            commit    => $one,
            iteration => 1,
            path      => 'f.txt',
            sections  => [{name => 'top', package => undef, lines => [[1, 5]], doc_lines => []}, {name => 'rest', package => undef, lines => [[6, 20]], doc_lines => []}],
        },
        "the earlier commit with the same change id gives the previous split, all of it, though a later one changed the file too",
    );
};

subtest previous_split_renamed => sub {
    my $dir   = make_repo();
    my @lines = map { "line $_ of the file\n" } 1 .. 20;
    my $text  = sub (%set) {
        join '' => map { $set{$_} // $lines[$_ - 1] } 1 .. 20;
    };
    my $base = commit_file($dir, 'Base', 'a.txt' => $text->());
    commit_file($dir, 'Edit', 'a.txt' => $text->(2 => "two\n"));
    my $repo = Review::Helper::VCS->detect($dir);
    my $db   = Review::Helper::DB->open(Review::Helper::Builder->new(repo => $repo)->build(base => $base));
    fill_splits($repo, $db, sub ($about) { [{name => 'top', lines => [[1, 10]]}, {name => 'bottom', lines => [[11, 20]]}] });

    # Rewritten: the commit now also moves the file and edits line 15.
    run_git($dir, qw/reset -q --hard/, $base);
    my $move = commit_file($dir, 'Edit', 'a.txt' => undef, 'b.txt' => $text->(2 => "two\n", 15 => "fifteen\n"));
    Review::Helper::Builder->new(repo => $repo, db => $db)->iterate;

    my ($item) = grep { $_->{type} eq 'split' && $_->{about}->{commit} eq $move } @{$CLASS->new(repo => $repo, db => $db)->sheet->{items}};
    is(
        $item->{about}->{previous},
        {
            commit    => T(),
            iteration => 1,
            path      => 'a.txt',
            sections  => [{name => 'top', package => undef, lines => [[1, 10]], doc_lines => []}, {name => 'bottom', package => undef, lines => [[11, 20]], doc_lines => []}],
        },
        'the previous split of the old path, as stored',
    );
};

subtest unchanged_content => sub {
    my $dir  = make_repo();
    my $text = join '' => map { "line $_\n" } 1 .. 5;
    my $base = commit_file($dir, 'Base', 'a.txt' => $text, 'run.sh' => "echo hi\n", 'empty.txt' => '');
    run_git($dir, qw/update-index --chmod=+x run.sh/);
    commit_file($dir, 'Move and chmod', 'a.txt' => undef, 'b.txt' => $text, 'new.txt' => '');
    my $repo  = Review::Helper::VCS->detect($dir);
    my $db    = Review::Helper::DB->open(Review::Helper::Builder->new(repo => $repo)->build(base => $base));
    my %files = map { @$_ } @{$db->dbh->selectall_arrayref(q{SELECT path, status FROM file_change})};
    is(\%files, {'b.txt' => 'R', 'run.sh' => 'M', 'new.txt' => 'A'}, 'a pure rename, a mode change and an empty added file');

    my @splits = grep { $_->{type} eq 'split' } @{$CLASS->new(repo => $repo, db => $db)->sheet->{items}};
    is([map { $_->{about}->{path} } @splits], ['new.txt'], 'a rename or mode change alone has no split item; an added file has one');
};

subtest renamed_split => sub {
    my $dir      = make_repo();
    my $text     = join '' => map { "line $_ of the file\n" } 1 .. 10;
    my $base     = commit_file($dir, 'Base',   'a.txt' => $text);
    my $revision = commit_file($dir, 'Rename', 'a.txt' => undef, 'b.txt' => $text =~ s/line 5 of the file\n//r);
    my $repo     = Review::Helper::VCS->detect($dir);
    my $db       = Review::Helper::DB->open(Review::Helper::Builder->new(repo => $repo)->build(base => $base));
    my $about    = items_by_id($CLASS->new(repo => $repo, db => $db)->sheet)->{'split:1'}->{about};

    like($about, {path => 'b.txt', old_path => 'a.txt', status => 'R'}, 'a renamed file names its old path');
    fill_splits($repo, $db, sub ($about) { [{name => 'text', lines => [[1, 9]]}, {name => 'gone', old_lines => [[5, 5]]}] });
    is(
        $db->dbh->selectall_arrayref('SELECT name, old_ranges, deleted FROM section', {Slice => {}}),
        [{name => 'text', old_ranges => '[]', deleted => 0}, {name => 'gone', old_ranges => '[[5,5]]', deleted => 1}],
        'old lines of a renamed file count in its old path',
    );
};

subtest guide => sub {
    my $t        = setup();
    my $revision = $t->{revision};
    my $data     = $t->{sheet}->sheet;

    my $step  = sub ($target, %rest) { +{target => $target, commentary => 'Plain words.', %rest} };
    my %cases = (
        "'steps' must be a non-empty array"                                      => [],
        'step 1: must be an object'                                              => ['x'],
        "step 1: unknown field 'x'"                                              => [$step->({type => 'summary'}, x => 1)],
        "step 1: 'commentary' must be a non-empty string"                        => [{target => {type => 'summary'}}],
        "step 1: 'commentary' is over 400 characters"                            => [$step->({type => 'summary'}, commentary => 'a' x 401)],
        'step 1: target: must be an object with a type'                          => [$step->(undef)],
        "step 1: target: unknown type 'x'"                                       => [$step->({type => 'x'})],
        "step 1: target: unknown field 'commit'"                                 => [$step->({type => 'summary', commit => $revision})],
        "step 1: target: 'commit': must be a commit's revision id"               => [$step->({type => 'commit'})],
        "step 1: target: 'path' must be a path changed in commit $revision"      => [$step->({type => 'file', commit => $revision, path => 'x'})],
        "step 1: target: no section 'nope' in 'lib/Foo.pm'"                      => [$step->({type => 'section', commit => $revision, path => 'lib/Foo.pm', section => {name => 'nope'}})],
        "step 1: target: no section 'one' in 'lib/Foo.pm'"                       => [$step->({type => 'diff',    commit => $revision, path => 'lib/Foo.pm', section => {name => 'one', package => 'Bar'}})],
        "step 1: target: 'section' must be an object with a 'name'"              => [$step->({type => 'section', commit => $revision, path => 'lib/Foo.pm', section => 'one'})],
        "step 1: target: section 'header' in 'lib/Foo.pm' has no change to show" => [$step->({type => 'diff',    commit => $revision, path => 'lib/Foo.pm', section => {name => 'header', package => 'Foo'}})],
        "step 1: target: no flag 'zz' in this iteration; 'flag' takes a note id" => [$step->({type => 'flag', flag => 'zz'})],
        "step 1: target: 'path' must be a path in commit $revision"              => [$step->({type => 'view', commit => $revision, path => 'nope.txt', lines => [1, 1]})],
        "step 1: highlight: 'side' must be 'new' on a view step"                 => [$step->({type => 'view', commit => $revision, path => 'keep.txt', lines => [1, 3]}, highlight => [{path => 'keep.txt', side => 'old', lines => [1, 1]}])],
        "step 1: 'highlight' needs a target in a commit"                         => [$step->({type => 'summary'}, highlight => [{path => 'style.scss', side => 'new', lines => [1, 1]}])],
        "step 1: 'highlight' must be an array"                                   => [$step->({type => 'commit', commit => $revision}, highlight => {})],
        "step 1: highlight: 'side' must be 'old' or 'new'"                       => [$step->({type => 'commit', commit => $revision}, highlight => [{path => 'style.scss', side => 'x', lines => [1, 1]}])],
        "step 1: highlight: 'path' must be a path changed in commit $revision"   => [$step->({type => 'commit', commit => $revision}, highlight => [{path => 'x', side => 'new', lines => [1, 1]}])],
        "step 1: target: 'lines': start is after end"                            => [$step->({type => 'view', commit => $revision, path => 'keep.txt', lines => [3, 1]})],
        "step 1: highlight: 'lines': must be [start, end]"                       => [$step->({type => 'commit', commit => $revision}, highlight => [{path => 'style.scss', side => 'old', lines => [0, 9]}])],
        'step 1: highlight: must be an object with path, side and lines'         => [$step->({type => 'commit', commit => $revision}, highlight => ['x'])],
    );
    for my $error (sort keys %cases) {
        is(errors_of($t->{sheet}, partial($data, 'guide:1' => {steps => $cases{$error}})), ["guide:1: $error"], $error);
    }

    for my $text ('Uses `x`.', 'Calls a->b.', 'In Foo::Bar.', 'Calls run().', 'Reads $x.', 'Reads @list.', 'Reads %hash.') {
        is(
            errors_of($t->{sheet}, partial($data, 'guide:1' => {steps => [$step->({type => 'summary'}, commentary => $text)]})),
            ["guide:1: step 1: 'commentary' must be read aloud: no backticks, '->', '::', '()', or a sigil before a word"], "code token in: $text"
        );
    }

    my @steps = (
        $step->({type => 'summary'}, commentary => 'a' x 400),
        $step->({type => 'commit',  commit => $revision}),
        $step->({type => 'file',    commit => $revision, path => 'lib/Foo.pm'}),
        $step->({type => 'section', commit => $revision, path => 'lib/Foo.pm', section => {name => 'sub one', package => 'Foo'}}),
        $step->({type => 'diff',    commit => $revision}),
        $step->({type => 'diff',    commit => $revision, path => 'style.scss'}),
        $step->({type => 'view',    commit => $revision, path => 'style.scss', lines => [1, 8]}, highlight => [{path => 'style.scss', side => 'new', lines => [2, 2]}]),
        $step->({type => 'view',    commit => $revision, path => 'keep.txt',   lines => [1, 9]}, highlight => [{path => 'keep.txt',   side => 'new', lines => [2, 30]}]),
        $step->({type => 'flag',    flag   => $t->{note}}, highlight => [{path => 'lib/Foo.pm', side => 'new', lines => [4, 4]}], commentary => 'Costs 5% more; worth it.'),
    );
    my $result = $t->{sheet}->fill(partial($data, 'guide:1' => {steps => \@steps}, "note:$t->{note}" => {commit => $revision, path => 'lib/Foo.pm', lines => [4, 4]}));
    is($result->{filled}, 2, 'flag target placed in the same sheet');

    my $rows = $t->{db}->dbh->selectall_arrayref('SELECT position, target, highlight, commentary FROM guide_step ORDER BY position', {Slice => {}});
    is(scalar(@$rows),                                                                9,                                             'steps stored, a view of an unchanged file included, its lines past the end too (not checked)');
    is([$JSON->decode($rows->[6]->{target}), $JSON->decode($rows->[6]->{highlight})], [$steps[6]->{target}, $steps[6]->{highlight}], 'target and highlight JSON');
    is($rows->[0]->{highlight},                                                       '[]',                                          'highlight defaults to empty');
    ok(!items_by_id($t->{sheet}->sheet)->{'guide:1'}, 'guide done');

    my $guide = (grep { $_->{id} eq 'guide:1' } @{$t->{sheet}->items($t->{sheet}->context)})[0];
    my ($flag) = grep { $_->{type} eq 'flag' } @{$t->{sheet}->sheet(all => 1)->{items}};
    is($flag->{about}->{note}, $t->{note}, "a flag item's about gives the note id a flag target names");
    my @again = (
        $step->({type => 'commit', commit => $revision}),
        $step->({type => 'flag',   flag   => $flag->{about}->{note}}, highlight => [{path => 'lib/Foo.pm', side => 'new', lines => [4, 4]}]),
    );
    $t->{sheet}->fill({%$data, items => [{%$guide, fields => {steps => \@again}}]});
    is(
        [map { $JSON->decode($_->[0]) } @{$t->{db}->dbh->selectall_arrayref('SELECT target FROM guide_step ORDER BY position')}],
        [{type => 'commit', commit => $revision}, {type => 'flag', flag => $t->{note}}],
        'a new guide replaces the old one, a flag placed by an earlier fill accepted',
    );

    # A later re-split leaves a step on a section the page no longer shows.
    my $guide_of = sub { items_by_id($t->{sheet}->sheet)->{'guide:1'} };
    my $foo      = $step->({type => 'section', commit => $revision, path => 'lib/Foo.pm', section => {name => 'sub one', package => 'Foo'}});
    $t->{sheet}->fill(partial($t->{sheet}->sheet(all => 1), 'guide:1' => {steps => [$foo]}));
    ok(!$guide_of->(), 'guide done, its section changed');

    my $resplit = sub ($sections) {
        $t->{db}->dbh->do(q{INSERT INTO request (iteration, kind, target, revision, path, status, created) VALUES (1, 'split', 'file', ?, 'lib/Foo.pm', 'open', 1)}, undef, $revision);
        fill_splits(
            $t->{repo},
            $t->{db},
            sub ($about) {
                $about->{path} eq 'lib/Foo.pm' ? [map { +{package => 'Foo', %$_} } @$sections] : undef;
            }
        );
    };
    $resplit->([{name => 'header', lines => [[1, 1]]}, {name => 'subs', lines => [[3, 9]]}, {name => 'sub one', lines => [[11, 11]]}]);
    is($guide_of->()->{fields}->{steps},                                                    [{%$foo, highlight => []}],                                                           'asked for again when its section is left untouched, with its steps');
    is(errors_of($t->{sheet}, partial($t->{sheet}->sheet, 'guide:1' => {steps => [$foo]})), ["guide:1: step 1: target: section 'sub one' in 'lib/Foo.pm' has no change to show"], 'the same steps say why');

    $t->{sheet}->fill(partial($t->{sheet}->sheet, 'guide:1' => {steps => [$step->({type => 'file', commit => $revision, path => 'lib/Foo.pm'})]}));
    ok(!$guide_of->(), 'done again once rewritten');
    $t->{sheet}->fill(partial($t->{sheet}->sheet(all => 1), 'guide:1' => {steps => [{%$foo, target => {%{$foo->{target}}, section => {name => 'subs', package => 'Foo'}}}]}));
    $resplit->([{name => 'header', lines => [[1, 1]]}, {name => 'sub one', lines => [[3, 5]]}, {name => 'sub two', lines => [[7, 9]]}, {name => 'end', lines => [[11, 11]]}]);
    ok($guide_of->(), 'asked for again when its section is gone');
};

# A squashed review of setup()'s change, split into topics.
sub topics_setup() {
    my $t      = setup(split => 0);
    my ($base) = $t->{db}->dbh->selectrow_array('SELECT parent FROM commit_entry');
    my $db     = Review::Helper::DB->open(Review::Helper::Builder->new(repo => $t->{repo})->build(squash => 1, base => $base, file => "$t->{dir}/.git/topics.sqlite"));
    return {%$t, db => $db, sheet => $CLASS->new(repo => $t->{repo}, db => $db, journal => $t->{journal})};
}

my $entries = sub ($db) { $db->dbh->selectall_arrayref('SELECT c.id, c.position, c.topic, c.what, f.path FROM commit_entry c LEFT JOIN file_change f ON f.commit_id = c.id ORDER BY c.position, f.path', {Slice => {}}) };

subtest topics_item => sub {
    my $t     = topics_setup();
    my $items = items_by_id($t->{sheet}->sheet);
    is(
        $items->{'topics:1'},
        {id => 'topics:1', type => 'topics', rev => T(), about => {paths => ['lib/Foo.pm', 'style.scss'], unassigned => ['lib/Foo.pm', 'style.scss']}, fields => {topics => undef}},
        'a squashed iteration asks for its topics; required, every file in none yet',
    );
    ok(!items_by_id(setup(split => 0)->{sheet}->sheet)->{'topics:1'}, 'a history review has no topics item');

    my $bad = sub ($topics) { errors_of($t->{sheet}, partial($t->{sheet}->sheet, 'topics:1' => {topics => $topics})) };
    is($bad->('x'), ["topics:1: 'topics' must be a non-empty array of { name, paths }"], 'an array');
    is($bad->([]),  ["topics:1: 'topics' must be a non-empty array of { name, paths }"], 'not empty');
    is(
        $bad->([{name => ' A', paths => ['lib/Foo.pm'], x => 1}, {name => ' ', paths => ['style.scss']}, 'z']),
        [
            "topics:1: topic 1: unknown field 'x'",
            "topics:1: topic 2: 'name' must be a non-empty string with no control character",
            "topics:1: topic 3: must be an object with 'name' and 'paths'",
        ],
        'names and fields checked',
    );
    is($bad->([{name => 'A', paths => ['lib/Foo.pm']}, {name => ' A ', paths => ['style.scss']}]), ["topics:1: topic 2: name 'A' repeats"], 'names repeat once trimmed');
    is(
        $bad->([{name => "A\0", paths => ['lib/Foo.pm']}, {name => "B\nC", paths => ['style.scss']}]),
        [
            "topics:1: topic 1: 'name' must be a non-empty string with no control character",
            "topics:1: topic 2: 'name' must be a non-empty string with no control character",
        ],
        'a name holds no control character, so none reads as no topic',
    );
    is(
        $bad->([{name => 'A', paths => ['lib/Foo.pm', 'nope.txt']}, {name => 'A', paths => ['lib/Foo.pm']}, {name => 'B', paths => []}]),
        [
            "topics:1: topic 1: 'nope.txt' is not a path of this iteration",
            "topics:1: topic 2: name 'A' repeats",
            "topics:1: topic 2: 'lib/Foo.pm' is already in topic 1",
            "topics:1: topic 3: 'paths' must be a non-empty array of paths",
            "topics:1: in no topic: 'style.scss'",
        ],
        'every path in exactly one topic, names unique',
    );
    is(
        $entries->($t->{db}), [
            map {
                hash { field topic => undef; field path => $_; etc() }
            } 'lib/Foo.pm',
            'style.scss'
        ],
        'nothing written'
    );

    $t->{sheet}->fill(partial($t->{sheet}->sheet, 'topics:1' => {topics => [{name => " All\t", paths => ['style.scss', 'lib/Foo.pm']}]}));
    is(
        $entries->($t->{db}), [
            map {
                hash { field position => 1; field topic => 'All'; field path => $_; etc() }
            } 'lib/Foo.pm',
            'style.scss'
        ],
        'a small review keeps one topic'
    );
    $items = items_by_id($t->{sheet}->sheet(all => 1));
    is($items->{'topics:1'}->{fields}, {topics => [{name => 'All', paths => ['lib/Foo.pm', 'style.scss']}]}, 'done, listed with all as filled');
    ok(!items_by_id($t->{sheet}->sheet)->{'topics:1'}, 'and left out otherwise');

    my ($id) = $t->{db}->dbh->selectrow_array('SELECT id FROM commit_entry');
    my $data = partial($t->{sheet}->sheet(all => 1), 'topics:1' => {topics => [{name => 'All', paths => ['style.scss', 'lib/Foo.pm']}]}, "commit:$id" => {what => 'W', why => 'Y', how => 'H'});
    is(errors_of($t->{sheet}, $data), [],                                                 'the topics item sent back as it came is no topics change');
    is($entries->($t->{db})->[0],     hash { field id => $id; field what => 'W'; etc() }, 'so the rest of the sheet fills');
};

subtest topics_fill => sub {
    my $t   = topics_setup();
    my $db  = $t->{db};
    my $dbh = $db->dbh;
    my ($revision, $id) = $dbh->selectrow_array('SELECT revision, id FROM commit_entry');

    $t->{sheet}->fill(partial($t->{sheet}->sheet, "commit:$id" => {what => 'W', why => 'Y', how => 'H'}, "note:$t->{note}" => {commit => $revision, path => undef}));
    $dbh->do(q{INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, kind, sentence, created) VALUES ('css', ?, 'style.scss', 2, 2, 'yellow', 'note', 'Blue.', 1)}, undef, $id);
    my $fb = $db->add_feedback(iteration => 1, target => 'commit', revision => $revision, body => 'On all of it.');
    my $rq = $db->add_request(iteration => 1, kind => 'debate', target => 'commit', revision => $revision);
    $dbh->do(q{INSERT INTO iteration (number, base, head, pin, created) SELECT 0, base, head, 'r0', created FROM iteration WHERE number = 1});
    my $old_fb = $db->add_feedback(iteration => 0, target => 'commit', revision => $revision, body => 'Earlier.');
    $db->add_feedback(iteration => 1, target => 'line', revision => $revision, path => 'style.scss', line => 2, side => 'new', body => 'Blue?');

    my $data = partial($t->{sheet}->sheet, 'topics:1' => {topics => [{name => 'Perl', paths => ['lib/Foo.pm']}, {name => 'Styles', paths => ['style.scss']}]});
    my ($guide) = grep { $_->{type} eq 'guide' } @{$t->{sheet}->sheet->{items}};
    push @{$data->{items}} => {%$guide, fields => {steps => [{target => {type => 'summary'}, commentary => 'Hi.'}]}};
    is(errors_of($t->{sheet}, $data), ['guide:1: the topics change in this sheet; fill this item from the next sheet'], 'nothing that names an entry fills beside the topics');

    $t->{sheet}->fill(partial($t->{sheet}->sheet, 'topics:1' => {topics => [{name => 'Perl', paths => ['lib/Foo.pm']}, {name => 'Styles', paths => ['style.scss']}]}));
    my $rows = $entries->($db);
    is($rows, [hash { field position => 1; field topic => 'Perl'; field what => undef; field path => 'lib/Foo.pm'; etc() }, hash { field position => 2; field topic => 'Styles'; field what => undef; field path => 'style.scss'; etc() }], 'one entry per topic, unexplained');
    ok(!$dbh->selectrow_array('SELECT 1 FROM commit_entry WHERE id = ?', undef, $id), 'the entry of the whole change went: no topic has all its files');
    my %entry = map { ($_->{topic} => $_->{id}) } @$rows;
    is(
        $dbh->selectall_arrayref('SELECT note_id, commit_id FROM flag ORDER BY commit_id'),
        [[$t->{note}, $entry{Perl}], ['css', $entry{Styles}]],
        'a flag follows its path; one on the whole change goes to the first topic',
    );
    is([$dbh->selectrow_array('SELECT target, revision, topic FROM feedback WHERE id = ?', undef, $fb)], ['review', $revision, undef], 'feedback on the entry that went moves to the review, its commit kept as context');
    is([$dbh->selectrow_array('SELECT target, revision, topic FROM request WHERE id = ?',  undef, $rq)], ['review', $revision, undef], 'a request too');
    is([$dbh->selectrow_array('SELECT target, topic FROM feedback WHERE id = ?', undef, $old_fb)], ['commit', undef], 'feedback of another iteration is left as it is');

    my $topic_fb = $db->add_feedback(iteration => 1, target => 'commit', revision => $revision, topic => 'Styles', body => 'Styles?');
    my $topic_rq = $db->add_request(iteration => 1, kind => 'debate', target => 'commit', revision => $revision, topic => 'Styles');
    my $other_fb = $db->add_feedback(iteration => 0, target => 'commit', revision => $revision, topic => 'Styles', body => 'Earlier styles.');
    my $items    = items_by_id($t->{sheet}->sheet);
    is($items->{"commit:$entry{Styles}"}->{about}, hash { field topic => 'Styles'; field revision => $revision; etc() }, 'a commit item names its topic');
    $t->{sheet}->fill(partial($t->{sheet}->sheet, "commit:$entry{Styles}" => {what => 'Colours.', why => 'Y', how => 'H'}, "commit:$entry{Perl}" => {what => 'Code.', why => 'Y', how => 'H'}));

    # Renamed with the same files: the entry, its text and its feedback stay.
    $t->{sheet}->fill(partial($t->{sheet}->sheet(all => 1), 'topics:1' => {topics => [{name => 'Perl', paths => ['lib/Foo.pm']}, {name => 'Look', paths => ['style.scss']}]}));
    is($entries->($db), [hash { field id => $entry{Perl}; field what => 'Code.'; etc() }, hash { field id => $entry{Styles}; field topic => 'Look'; field what => 'Colours.'; etc() }], 'a renamed topic keeps its entry and text');
    is([$dbh->selectrow_array('SELECT target, topic FROM feedback WHERE id = ?', undef, $topic_fb)], ['commit', 'Look'],   'and its feedback follows the new name');
    is([$dbh->selectrow_array('SELECT target, topic FROM request WHERE id = ?',  undef, $topic_rq)], ['commit', 'Look'],   'its requests too');
    is([$dbh->selectrow_array('SELECT target, topic FROM feedback WHERE id = ?', undef, $other_fb)], ['commit', 'Styles'], 'not feedback of another iteration: a rename is this iteration\'s');

    # Files moved: kept by name, but the text no longer fits.
    $t->{sheet}->fill(partial($t->{sheet}->sheet(all => 1), 'topics:1' => {topics => [{name => 'Look', paths => ['style.scss', 'lib/Foo.pm']}]}));
    is(
        $entries->($db), [
            map {
                hash { field id => $entry{Styles}; field topic => 'Look'; field what => undef; field path => $_; etc() }
            } 'lib/Foo.pm',
            'style.scss'
        ],
        'a topic whose files change is explained afresh'
    );
    is($dbh->selectall_arrayref('SELECT DISTINCT commit_id FROM flag'), [[$entry{Styles}]], 'flags follow their files');

    # A file waiting in no topic, as an iterate leaves it, with feedback there.
    $dbh->do(q{INSERT INTO commit_entry (iteration, position, revision, subject, message) SELECT iteration, 2, revision, subject, message FROM commit_entry WHERE id = ?}, undef, $entry{Styles});
    $dbh->do(q{UPDATE file_change SET commit_id = ? WHERE path = 'style.scss'},                                                                                            undef, $dbh->last_insert_id(undef, undef, 'commit_entry', 'id'));
    my $waiting = $db->add_feedback(iteration => 1, target => 'commit', revision => $revision, body => 'Waiting.');
    $t->{sheet}->fill(partial($t->{sheet}->sheet, 'topics:1' => {topics => [{name => 'Look', paths => ['style.scss', 'lib/Foo.pm']}]}));
    is([$dbh->selectrow_array('SELECT target, topic FROM feedback WHERE id = ?', undef, $waiting)], ['review', ''], 'feedback on the files not in a topic yet keeps a topic of the empty string');
};

subtest topics_targets => sub {
    my $t = topics_setup();
    my ($revision) = $t->{db}->dbh->selectrow_array('SELECT revision FROM commit_entry');
    $t->{sheet}->fill(partial($t->{sheet}->sheet, 'topics:1' => {topics => [{name => 'Perl', paths => ['lib/Foo.pm']}, {name => 'Styles', paths => ['style.scss']}]}));
    my %entry = map { @$_ } @{$t->{db}->dbh->selectall_arrayref('SELECT topic, id FROM commit_entry')};

    my $note = sub (%fields) { errors_of($t->{sheet}, partial($t->{sheet}->sheet, "note:$t->{note}" => {commit => $revision, %fields})) };
    is($note->(path => undef), ["note:$t->{note}: 'commit': commit $revision is split into topics; give 'topic'"], 'a whole-change note names its topic');
    is($note->(path => undef,        topic => 'Nope'), ["note:$t->{note}: 'commit': commit $revision has no topic 'Nope'"],                          'one that exists');
    is($note->(path => 'style.scss', topic => 'Perl'), ["note:$t->{note}: 'path': 'style.scss' is not changed in topic 'Perl' of commit $revision"], 'a path must be in the topic named');

    my $guide = sub (@targets) {
        my $steps = [map { +{target => $_, commentary => 'Look here.'} } @targets];
        return errors_of($t->{sheet}, partial($t->{sheet}->sheet, 'guide:1' => {steps => $steps}));
    };
    is($guide->({type => 'commit', commit => $revision}),                                      ["guide:1: step 1: target: 'commit': commit $revision is split into topics; give 'topic'"], 'a commit step names its topic');
    is($guide->({type => 'diff', commit => $revision, topic => 'Nope'}),                       ["guide:1: step 1: target: 'commit': commit $revision has no topic 'Nope'"],                'an existing one');
    is($guide->({type => 'file', commit => $revision, path => 'lib/Foo.pm', topic => 'Perl'}), ["guide:1: step 1: target: unknown field 'topic'"],                                         'only commit and diff steps take one: a path names its topic');

    $t->{sheet}->fill(partial(
        $t->{sheet}->sheet,
        "note:$t->{note}" => {commit => $revision, path => 'lib/Foo.pm', lines => [3, 5]},
        'guide:1'         => {
            steps => [
                {target => {type => 'commit', commit => $revision, topic => 'Styles'},     commentary => 'The styles.'},
                {target => {type => 'diff',   commit => $revision, path  => 'style.scss'}, highlight  => [{path => 'style.scss', side => 'new', lines => [2, 2]}], commentary => 'The colour.'},
            ]
        }
    ));
    is($t->{db}->dbh->selectall_arrayref('SELECT commit_id FROM flag'), [[$entry{Perl}]], 'a note lands in the topic holding its path');
    my $done = sub { !items_by_id($t->{sheet}->sheet)->{'guide:1'} };
    ok($done->(), 'the guide is done');

    $t->{sheet}->fill(partial($t->{sheet}->sheet(all => 1), 'topics:1' => {topics => [{name => 'Perl', paths => ['lib/Foo.pm', 'style.scss']}]}));
    ok(!$done->(), 'asked for again when a topic it names is gone');
};

done_testing;
