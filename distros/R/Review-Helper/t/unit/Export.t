# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use Cwd qw/abs_path/;
use File::Temp qw/tempdir/;
use Storable qw/dclone/;

use TestRepo qw/make_repo commit_file run_git/;
use Review::Helper::Builder;
use Review::Helper::DB;
use Review::Helper::Export;
use Review::Helper::Registry;
use Review::Helper::VCS;
use Review::Helper::Util qw/json_decode/;

my $CLASS = 'Review::Helper::Export';

my $dir  = make_repo();
my $base = commit_file($dir, 'Base',   'lib/A.pm' => "package A;\nsub a { 1 }\n1;\n");
my $head = commit_file($dir, 'Change', 'lib/A.pm' => "package A;\nsub a { 2 }\nsub b { 3 }\n1;\n", 'b.txt' => "b\n");

my $file = Review::Helper::Builder->new(repo => Review::Helper::VCS->detect($dir))->build(base => $base, title => 'Add b');
my $db   = Review::Helper::DB->open($file);
my $dbh  = $db->dbh;
my $id   = $db->review->{id};

$dbh->do(q{UPDATE iteration SET what = ?, why = 'Because.', how = 'So.'}, undef, "Caf\x{e9} \x{263a}");
$dbh->do(q{UPDATE file_change SET what = 'Changed.'});
$dbh->do(q{INSERT INTO feedback (iteration, target, body, created, updated, status) VALUES (1, 'review', 'Mine.', 1, 1, 'open')});
$dbh->do(q{INSERT INTO request (iteration, kind, target, status, created) VALUES (1, 'debate', 'review', 'open', 1)});
$dbh->do(q{CREATE TABLE x_test_notes (n INTEGER PRIMARY KEY, body TEXT NOT NULL)});
$dbh->do(q{INSERT INTO x_test_notes (n, body) VALUES (2, 'two'), (1, 'one')});
$dbh->do(q{ALTER TABLE file_change ADD COLUMN x_test_score INTEGER});
$dbh->do(q{UPDATE file_change SET x_test_score = 7});

my $exporter = $CLASS->new(db => $db);
my $export   = $exporter->export;

subtest export => sub {
    is([@$export{qw/format format_version/}], ['review-export', 1], 'header');
    like($export->{generator}, qr/^Review::Helper /, 'generator');

    my $tables = $export->{tables};
    is(
        [sort keys %$tables],
        [qw/commit_entry file_change flag guide_step iteration journal_entry meta review section/],
        'every format table but feedback, request and flag_seen; no extension tables',
    );
    ok(!(grep { $_ eq 'x_test_score' } @{$tables->{file_change}{columns}}), 'no extension columns');

    my $text = $exporter->encode($export);
    is(json_decode($text), $export, 'encoding round-trips');
    my $rows = 0;
    $rows += @{$_->{rows}} for values %$tables;
    is(scalar(grep { m/^ {8}\[/ } split /\n/ => $text), $rows, 'one row per line');
    is($exporter->encode($exporter->export),            $text, 'stable output');

    like(dies { $CLASS->new->export }, qr/'db' is required/, 'needs db');
};

# A second clone holds the same commits, as a teammate's would.
my $clone = abs_path(tempdir(CLEANUP => 1));
run_git($clone, qw/clone -q/, $dir, '.');
my $clone_repo = Review::Helper::VCS->detect($clone);
my $importer   = $CLASS->new(repo => $clone_repo);

subtest 'round trip' => sub {
    my $result = $importer->restore(dclone($export), name => 'shared');
    is($result, {file => "$clone/.git/review-helper/shared.sqlite", missing => []}, 'created, nothing missing');

    my $copy = Review::Helper::DB->open($result->{file});
    is($CLASS->new(db => $copy)->export,                             $export, 'same tables');
    is($copy->dbh->selectrow_array('SELECT count(*) FROM feedback'), 0,       'no feedback');

    my $pinned = run_git($clone, qw/rev-parse/, "refs/review-helper/$id/1");
    chomp($pinned);
    is($pinned,                                                                  $head,           'iteration pinned');
    is(Review::Helper::Registry->new(repo => $clone_repo)->reviews->{$id}{path}, $result->{file}, 'registered');

    is($importer->restore(dclone($export), name => 'again')->{file}, $result->{file}, 're-import goes to the registered file');
    ok(!-e "$clone/.git/review-helper/again.sqlite", 'no second file');

    my $elsewhere = "$clone/.git/review-helper/elsewhere.sqlite";
    like(dies { $importer->restore(dclone($export), file => $elsewhere) }, qr/Review \Q$id\E is already in this repository/, 'one copy per repository');
    ok(!-e $elsewhere, 'no file left');
};

subtest 'imports open' => sub {
    my $other  = make_repo();
    my $repo   = Review::Helper::VCS->detect($other);
    my $closed = dclone($export);
    my $review = $closed->{tables}{review};
    my ($at)   = grep { $review->{columns}[$_] eq 'state' } 0 .. $#{$review->{columns}};
    $review->{rows}[0][$at] = 'closed';

    my $result = $CLASS->new(repo => $repo)->restore($closed, name => 'closed');
    is(Review::Helper::DB->open($result->{file})->review->{state},          'open', 'review open');
    is(Review::Helper::Registry->new(repo => $repo)->reviews->{$id}{state}, 'open', 'registered open');
};

# Readers ignore tables they do not know: a merge into a file holding one
# is not blamed on the export.
subtest 'a file with an extra table' => sub {
    my $other  = make_repo();
    my $repo   = Review::Helper::VCS->detect($other);
    my $result = $CLASS->new(repo => $repo)->restore(dclone($export), name => 'extra');
    Review::Helper::DB->open($result->{file})->dbh->do('CREATE TABLE widget (id INTEGER)');
    ok(lives { $CLASS->new(repo => $repo)->restore(dclone($export)) }, 'the export merges in') or note($@);
    is(Review::Helper::DB->open($result->{file})->dbh->selectrow_array('SELECT COUNT(*) FROM widget'), 0, 'the extra table is left alone');

    my $again = $CLASS->new(db => Review::Helper::DB->open($result->{file}))->export;
    ok(!$again->{tables}{widget},                             'an export of that file leaves the extra table out');
    ok(lives { $CLASS->new(repo => $repo)->restore($again) }, 'and merges back into it') or note($@);
};

# Registering is part of the merge: when it fails, the file keeps what it
# held and a later import still merges and registers.
subtest 'registering fails on a merge' => sub {
    my $other  = make_repo();
    my $repo   = Review::Helper::VCS->detect($other);
    my $result = $CLASS->new(repo => $repo)->restore(dclone($export), name => 'unregistered');
    my $target = Review::Helper::DB->open($result->{file});
    $target->set_state('closed');
    Review::Helper::Registry->new(repo => $repo)->set_state($id, 'closed');

    my $changed = dclone($export);
    my $review  = $changed->{tables}{review};
    my ($at)    = grep { $review->{columns}[$_] eq 'title' } 0 .. $#{$review->{columns}};
    $review->{rows}[0][$at] = 'Changed title';

    {
        my $mock = mock 'Review::Helper::Registry' => (override => [register => sub { die "registry is locked\n" }]);
        like(dies { $CLASS->new(repo => $repo)->restore(dclone($changed)) }, qr/^registry is locked$/, 'the failure is reported');
    }
    is(
        [@{Review::Helper::DB->open($result->{file})->review}{qw/title state/}],
        ['Add b', 'closed'],
        'the file is left as it was',
    );
    is(Review::Helper::Registry->new(repo => $repo)->reviews->{$id}{state}, 'closed', 'and so is the registry');

    ok(lives { $CLASS->new(repo => $repo)->restore(dclone($changed)) }, 'a retry merges') or note($@);
    is(
        [@{Review::Helper::DB->open($result->{file})->review}{qw/title state/}],
        ['Changed title', 'open'],
        'and the file takes the export',
    );
    is(Review::Helper::Registry->new(repo => $repo)->reviews->{$id}{state}, 'open', 'registered open');
};

# Foreign keys are checked before registering: a commit failing on them
# would come after the registry was written.
subtest 'a row referring to a missing row' => sub {
    my $broken = dclone($export);
    my $fc     = $broken->{tables}{file_change};
    my ($at)   = grep { $fc->{columns}[$_] eq 'commit_id' } 0 .. $#{$fc->{columns}};
    $fc->{rows}[0][$at] = 9999;

    my $other = make_repo();
    my $repo  = Review::Helper::VCS->detect($other);
    like(dies { $CLASS->new(repo => $repo)->restore(dclone($broken), name => 'broken') }, qr/^Table 'file_change' has a row that refers to a missing 'commit_entry' row/, 'a new file is refused');
    ok(!-e "$other/.git/review-helper/broken.sqlite", 'no file left');
    is(Review::Helper::Registry->new(repo => $repo)->reviews, {}, 'nothing registered');

    my $result = $CLASS->new(repo => $repo)->restore(dclone($export), name => 'merge');
    Review::Helper::DB->open($result->{file})->set_state('closed');
    Review::Helper::Registry->new(repo => $repo)->set_state($id, 'closed');
    like(dies { $CLASS->new(repo => $repo)->restore(dclone($broken)) }, qr/^Table 'file_change' has a row that refers to a missing 'commit_entry' row/, 'so is a merge');
    is(Review::Helper::DB->open($result->{file})->review->{state},          'closed', 'the file is left as it was');
    is(Review::Helper::Registry->new(repo => $repo)->reviews->{$id}{state}, 'closed', 'and so is the registry');
};

subtest 'another review at the path' => sub {
    my $other   = make_repo();
    my $repo    = Review::Helper::VCS->detect($other);
    my $taken   = "$other/.git/review-helper/taken.sqlite";
    my $holder  = Review::Helper::DB->create($taken, title => 'Other');
    my $foreign = $holder->review->{id};
    like(dies { $CLASS->new(repo => $repo)->restore(dclone($export), file => $taken) }, qr/already exists and does not hold review \Q$id\E/, 'refused');
    is(Review::Helper::DB->open($taken)->review->{id},        $foreign, 'file untouched');
    is(Review::Helper::Registry->new(repo => $repo)->reviews, {},       'nothing registered');

    my $junk = "$other/.git/review-helper/junk.sqlite";
    open(my $fh, '>', $junk) or die "Cannot write $junk: $!";
    print $fh "not a database\n" x 100;
    close($fh);
    like(dies { $CLASS->new(repo => $repo)->restore(dclone($export), file => $junk) }, qr/already exists and does not hold review \Q$id\E/, 'a file that is not SQLite is refused the same way');

    my $newer = "$other/.git/review-helper/newer.sqlite";
    Review::Helper::DB->create($newer)->dbh->do(q{UPDATE meta SET value = '2' WHERE key = 'format_version'});
    like(dies { $CLASS->new(repo => $repo)->restore(dclone($export), file => $newer) }, qr/^Unsupported review file format version '2'/, 'so is a file of another format version');
};

subtest 're-import merges' => sub {
    my $origin = make_repo();
    commit_file($origin, 'Base', 'a.txt' => "a\n");
    my $one = commit_file($origin, 'One', 'a.txt' => "b\n");

    my $origin_repo = Review::Helper::VCS->detect($origin);
    my $built       = Review::Helper::Builder->new(repo => $origin_repo)->build(base => "$one~1", title => 'Merge');
    my $author      = Review::Helper::DB->open($built);
    my $rid         = $author->review->{id};
    $author->dbh->do(q{UPDATE iteration SET what = 'First.'});
    my ($cid) = $author->dbh->selectrow_array('SELECT id FROM commit_entry WHERE iteration = 1 LIMIT 1');
    $author->dbh->do(q{INSERT INTO flag (id, note_id, commit_id, color, kind, sentence, created) VALUES (?, ?, ?, 'red', 'other', 's', 1)},                                               undef, @$_) for [1, 'n1', $cid], [2, 'n2', $cid];
    $author->dbh->do(q{INSERT INTO flag (id, note_id, commit_id, path, line_start, line_end, color, kind, sentence, created) VALUES (3, 'n4', ?, 'a.txt', 1, 1, 'red', 'other', 's', 1)}, undef, $cid);
    $author->dbh->do(q{INSERT INTO flag (id, note_id, commit_id, color, kind, sentence, created) VALUES (?, ?, ?, 'yellow', 'other', 's', 1)},                                            undef, @$_) for [4,    'y1', $cid], [5, 'y2', $cid];
    $author->dbh->do(q{INSERT INTO journal_entry (id, iteration, kind, path, sentence, created) VALUES (?, 1, 'note', 'a.txt', ?, 1)},                                                    undef, @$_) for ['j1', 'Gone later.'], ['j2', 'First words.'];

    my $mine = abs_path(tempdir(CLEANUP => 1));
    run_git($mine, qw/clone -q/, $origin, '.');
    my $mine_repo = Review::Helper::VCS->detect($mine);
    my $file      = $CLASS->new(repo => $mine_repo)->restore($CLASS->new(db => $author)->export, name => 'merge')->{file};

    my $local = Review::Helper::DB->open($file);
    $local->add_feedback(iteration => 1, target => 'review', body => 'Keep me.');
    $local->add_request(iteration => 1, kind => 'debate', target => 'review', note => 'Me too.');
    $local->set_state('closed');
    $local->set_flag_seen($_, 'Ann', 1) for 1, 2, 3, 4, 5;

    my $two = commit_file($origin, 'Two', 'a.txt' => "c\n");
    Review::Helper::Builder->new(repo => $origin_repo, db => $author)->iterate;
    $author->dbh->do(q{UPDATE iteration SET what = 'Rewritten.' WHERE number = 1});
    $author->dbh->do(q{UPDATE commit_entry SET what = 'Explained.'});
    $author->dbh->do(q{DELETE FROM flag WHERE id = 2});
    $author->dbh->do(q{INSERT INTO flag (id, note_id, commit_id, color, kind, sentence, created) VALUES (2, 'n3', ?, 'red', 'other', 's', 1)}, undef, $cid);
    $author->dbh->do(q{UPDATE flag SET id = 99 WHERE id = 1});
    $author->dbh->do(q{UPDATE flag SET line_start = 2, line_end = 2 WHERE id = 3});
    $author->dbh->do(q{UPDATE flag SET color = 'red', color_reason = 'Worse than thought.' WHERE id = 4});
    $author->dbh->do(q{DELETE FROM journal_entry WHERE id = 'j1'});
    $author->dbh->do(q{UPDATE journal_entry SET sentence = 'Better words.' WHERE id = 'j2'});
    my $newer = $CLASS->new(db => $author)->export;

    my $result = $CLASS->new(repo => $mine_repo)->restore(dclone($newer), name => 'ignored');
    is($result, {file => $file, missing => [{iteration => 2, head => $two}]}, 'merged into the same file; new head missing');

    my $dbh = $local->dbh;
    is($dbh->selectcol_arrayref('SELECT number FROM iteration ORDER BY number'), [1, 2],                    'iteration added');
    is($dbh->selectcol_arrayref('SELECT what FROM iteration ORDER BY number'),   ['Rewritten.', undef],     'agent text replaced');
    is($dbh->selectcol_arrayref('SELECT DISTINCT what FROM commit_entry'),       ['Explained.'],            'commit text replaced');
    is($dbh->selectall_arrayref('SELECT id, sentence FROM journal_entry'),       [['j2', 'Better words.']], 'journal entries replaced with their iteration');
    is($dbh->selectcol_arrayref('SELECT body FROM feedback'),                    ['Keep me.'],              'feedback kept');
    is($dbh->selectcol_arrayref('SELECT note FROM request'),                     ['Me too.'],               'requests kept');
    is($dbh->selectcol_arrayref('SELECT flag FROM flag_seen ORDER BY flag'),     [5, 99],                   'seen marks follow their flag, not its old id; none on a flag that is gone or now covers other lines');
    ok(!$dbh->selectrow_array('SELECT 1 FROM flag_seen WHERE flag = 4'), 'nor on a flag the export turned from yellow to red: it is unseen again');
    is($local->review->{state},                                                   'open', 'open again');
    is(Review::Helper::Registry->new(repo => $mine_repo)->reviews->{$rid}{state}, 'open', 'registered open');
    is([grep { m{/2\z} } @{$mine_repo->pins($rid)}],                              [],     'iteration 2 not pinned yet');

    run_git($mine, qw/fetch -q origin/);
    is($CLASS->new(repo => $mine_repo)->restore(dclone($newer))->{missing}, [], 'nothing missing after the fetch');
    my $pinned = run_git($mine, qw/rev-parse/, "refs/review-helper/$rid/2");
    chomp($pinned);
    is($pinned,                                               $two,         're-pinned after the commit appears');
    is($dbh->selectcol_arrayref('SELECT body FROM feedback'), ['Keep me.'], 'feedback still kept');
};

subtest 'rejected exports' => sub {
    my $other    = make_repo();
    my $rejecter = $CLASS->new(repo => Review::Helper::VCS->detect($other));

    my %cases = (
        'not an export'     => [sub ($e) { $e->{format} = 'review-sheet' },                               qr/Not a review export/],
        'newer version'     => [sub ($e) { $e->{format_version} = 2 },                                    qr/Unsupported review export format version '2'/],
        'feedback included' => [sub ($e) { $e->{tables}{feedback} = {columns => ['id'], rows => []} },    qr/must not include these tables: feedback/],
        'marks included'    => [sub ($e) { $e->{tables}{flag_seen} = {columns => ['flag'], rows => []} }, qr/must not include these tables: flag_seen/],
        'unknown column'    => [
            sub ($e) {
                my $t = $e->{tables}{iteration};
                push @{$t->{columns}} => 'squished';
                push @$_              => 1 for @{$t->{rows}};
            },
            qr/no column named squished/,
        ],
        'missing table'  => [sub ($e) { delete $e->{tables}{guide_step} }, qr/^This review export was built by a different version of review-helper; export it again with this version, or import it with the version that built it \(it has no table 'guide_step'\)/],
        'missing column' => [
            sub ($e) {
                my $t  = $e->{tables}{iteration};
                my $at = (grep { $t->{columns}[$_] eq 'note' } 0 .. $#{$t->{columns}})[0];
                splice(@{$t->{columns}}, $at, 1);
                splice(@$_,              $at, 1) for @{$t->{rows}};
            },
            qr/^This review export was built by a different version of review-helper; export it again with this version, or import it with the version that built it \(table 'iteration' lacks columns: note\)/,
        ],
        'short row'   => [sub ($e) { pop @{$e->{tables}{meta}{rows}[0]} },                                          qr/row that does not match its columns/],
        'two reviews' => [sub ($e) { push @{$e->{tables}{review}{rows}} => $e->{tables}{review}{rows}[0] },         qr/exactly one review row/],
        'wrong pin'   => [sub ($e) { $e->{tables}{iteration}{rows}[0][$_] = 'refs/heads/main' for pin_column($e) }, qr/Iteration 1 must have pin/],
    );

    for my $name (sort keys %cases) {
        my ($change, $error) = @{$cases{$name}};
        my $bad = dclone($export);
        $change->($bad);
        like(dies { $rejecter->restore($bad, name => 'bad') }, $error, $name);
        ok(!-e "$other/.git/review-helper/bad.sqlite", "$name: no file left");
    }

    is(Review::Helper::Registry->new(repo => Review::Helper::VCS->detect($other))->reviews, {}, 'nothing registered');
};

subtest 'missing commits' => sub {
    my $other  = make_repo();
    my $repo   = Review::Helper::VCS->detect($other);
    my $result = $CLASS->new(repo => $repo)->restore(dclone($export));

    is($result->{file},    "$other/.git/review-helper/Add-b.sqlite", 'named after the title');
    is($result->{missing}, [{iteration => 1, head => $head}],        'missing head reported');
    is($repo->pins($id),   [],                                       'not pinned');
};

subtest 'file option' => sub {
    my $other  = make_repo();
    my $target = "$other/.git/review-helper/chosen.sqlite";
    my $result = $CLASS->new(repo => Review::Helper::VCS->detect($other))->restore(dclone($export), file => $target);
    is($result->{file}, $target, 'written where asked');

    like(dies { $CLASS->new->restore($export) }, qr/'repo' is required/, 'needs repo');
};

sub pin_column($e) {
    my $cols = $e->{tables}{iteration}{columns};
    return grep { $cols->[$_] eq 'pin' } 0 .. $#$cols;
}

# Tables it does not know are ignored, extension ones too; extension columns
# are skipped.
subtest 'extensions and unknown tables skipped' => sub {
    my $other = make_repo();
    my $ext   = dclone($export);
    $ext->{tables}{x_test_notes} = {columns => ['n'],  rows => [[1]]};
    $ext->{tables}{widget}       = {columns => ['id'], rows => [[1]]};
    my $fc = $ext->{tables}{file_change};
    push @{$fc->{columns}} => 'x_test_score';
    push @$_               => 7 for @{$fc->{rows}};

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings => @_ };
    my $result = $CLASS->new(repo => Review::Helper::VCS->detect($other))->restore($ext, name => 'ext');
    is(\@warnings, [], 'without a word');

    my $dbh = Review::Helper::DB->open($result->{file})->dbh;
    ok(!$dbh->selectrow_array(q{SELECT 1 FROM sqlite_master WHERE name IN ('x_test_notes', 'widget')}), 'tables not created');
};

done_testing;
