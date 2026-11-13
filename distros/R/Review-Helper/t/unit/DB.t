# Test origin: AI
use v5.36;
use Test2::V0;

use DBI;
use File::Temp qw/tempdir/;
use Review::Helper::DB;

my $tmp = tempdir(CLEANUP => 1);

sub slurp($path) {
    open(my $fh, '<:raw', $path) or die "open $path: $!";
    local $/;
    return scalar <$fh>;
}

subtest create => sub {
    my $path = "$tmp/sub/dir/one.sqlite";
    my $db   = Review::Helper::DB->create($path, title => "Caf\x{e9} change", source => 'https://example.com/pr/1');
    ok(-f $path, 'file created along with its directories');
    is($db->path, $path, 'path');

    is(
        {map { @$_ } @{$db->dbh->selectall_arrayref('SELECT key, value FROM meta')}},
        {format => 'review-file', format_version => '1', generator => "Review::Helper $Review::Helper::VERSION"},
        'meta rows',
    );

    is(
        $db->review,
        {
            id      => match qr/^[0-9a-f]{8}-[0-9a-f]{4}-7/,
            title   => "Caf\x{e9} change",
            source  => 'https://example.com/pr/1',
            created => match qr/^\d+$/,
            state   => 'open',
        },
        'review row, text round-trips as characters',
    );

    my @tables = sort map { $_->[0] } @{$db->dbh->selectall_arrayref(q{SELECT name FROM sqlite_master WHERE type = 'table'})};
    is(\@tables, [sort qw/meta review iteration commit_entry file_change section flag journal_entry guide_step feedback request flag_seen/], 'all tables');
    like(dies { $db->dbh->do(q{INSERT INTO flag (note_id, commit_id, color, kind, sentence, created) VALUES ('n', 1, 'green', 'other', 's', 1)}) },    qr/CHECK constraint failed/, 'color is yellow or red');
    like(dies { $db->dbh->do(q{INSERT INTO flag (note_id, commit_id, color, kind, sentence, created) VALUES ('n', 1, 'yellow', 'concern', 's', 1)}) }, qr/CHECK constraint failed/, 'kind is from the list');
    is($db->dbh->selectall_arrayref(q{SELECT name, tbl_name FROM sqlite_master WHERE type = 'index' AND sql IS NOT NULL ORDER BY name}), [['commit_entry_revision', 'commit_entry'], ['section_file', 'section']], 'sections are indexed by file, commits by revision and topic');

    like(dies { Review::Helper::DB->create($path) },                       qr/already exists/,               'refuses an existing file');
    like(dies { Review::Helper::DB->create("$tmp/x.sqlite", bogus => 1) }, qr/Unknown review fields: bogus/, 'unknown field');
    like(dies { Review::Helper::DB->create("$tmp/d;x/r.sqlite") },         qr/may not contain ';'/,          'a path with a semicolon');
    ok(!-e "$tmp/d;x" && !-e "$tmp/d", 'nothing written for it');
    open(my $fh, '>', "$tmp/semi;x.sqlite") or die "Cannot create '$tmp/semi;x.sqlite': $!";
    like(dies { Review::Helper::DB->open("$tmp/semi;x.sqlite") }, qr/may not contain ';'/, 'open refuses one too');

    my $fixed = Review::Helper::DB->create("$tmp/fixed.sqlite", id => 'abc', created => 5);
    is($fixed->review, {id => 'abc', title => undef, source => undef, created => 5, state => 'open'}, 'given id and created');

    my $bad = "$tmp/bad.sqlite";
    {
        no warnings qw/redefine/;
        local *Review::Helper::DB::gen_uuid = sub { die "uuid failed\n" };
        like(dies { Review::Helper::DB->create($bad) }, qr/^uuid failed$/, "failure rethrown");
    }
    ok(!-e $bad, 'partial file removed on failure');
};

subtest open => sub {
    my $path = "$tmp/two.sqlite";
    my $id   = Review::Helper::DB->create($path)->review->{id};
    my $db   = Review::Helper::DB->open($path);
    is($db->review->{id}, $id, 'opened');

    like(dies { Review::Helper::DB->open("$tmp/none.sqlite") }, qr/No such review file/, 'missing file');

    my $plain = "$tmp/plain.sqlite";
    DBI->connect("dbi:SQLite:dbname=$plain", '', '', {RaiseError => 1})->do('CREATE TABLE t (x)');
    like(dies { Review::Helper::DB->open($plain) }, qr/Not a review file/, 'other sqlite file');

    my $text = "$tmp/text.sqlite";
    open(my $fh, '>', $text) or die "Cannot write $text: $!";
    print $fh "not a database\n" x 100;
    close($fh);
    is([map { Review::Helper::DB->is_review_file($_) } $path, $plain, $text, "$tmp/none.sqlite"], [1, 0, 0, 0], 'is_review_file: only a review file');

    $db->dbh->do(q{UPDATE meta SET value = '2' WHERE key = 'format_version'});
    like(dies { Review::Helper::DB->open($path) }, qr/Unsupported review file format version '2'/, 'newer format version');
};

subtest txn_and_queries => sub {
    my $db = Review::Helper::DB->create("$tmp/three.sqlite");
    is($db->iterations,       [],    'no iterations');
    is($db->latest_iteration, undef, 'no latest iteration');

    my $insert = sub ($n) {
        $db->dbh->do('INSERT INTO iteration (number, base, head, pin, created) VALUES (?, ?, ?, ?, ?)', undef, $n, 'b', 'h', "refs/x/$n", 1);
    };

    is([$db->txn(sub { $insert->(1); $insert->(2); return (7, 8) })], [7, 8], 'txn returns the result');
    like(
        dies {
            $db->txn(sub { $insert->(3); die "boom\n" })
        },
        qr/^boom$/,
        'txn rethrows'
    );

    is([map { $_->{number} } @{$db->iterations}], [1, 2], 'rolled back the failed txn');
    is($db->latest_iteration->{number},           2,      'latest iteration');

    $db->set_state('closed');
    is($db->review->{state}, 'closed', 'state set');
    like(dies { $db->set_state('gone') }, qr/must be 'open' or 'closed'/, 'bad state');

    like(
        dies { $db->dbh->do('INSERT INTO commit_entry (iteration, position, revision, subject, message) VALUES (9, 1, ?, ?, ?)', undef, 's', 's', 'm') },
        qr/FOREIGN KEY/, 'foreign keys enforced'
    );

    my $entry = sub ($id, $it, $created) {
        $db->dbh->do(q{INSERT INTO journal_entry (id, iteration, kind, path, sentence, created) VALUES (?, ?, 'note', 'a.pm', 'S.', ?)}, undef, $id, $it, $created);
    };
    $entry->(@$_) for ['b', 1, 5], ['a', 1, 9], ['c', 2, 1];
    is([map { $_->{id} } @{$db->journal_entries(1)}], ['b', 'a'], "an iteration's journal entries, oldest first");

    my %none = (deleted => 0, added => 0, removed => 0, changed => 0);
    is($db->section_touched(\%none),           0, 'a section with no change is untouched');
    is($db->section_touched({%none, $_ => 1}), 1, "a section with '$_' set is touched") for qw/deleted added removed changed/;
};

subtest set_published => sub {
    my $db  = Review::Helper::DB->create("$tmp/published.sqlite");
    my $dbh = $db->dbh;
    $dbh->do(q{INSERT INTO iteration (number, base, head, pin, created) VALUES (1, 'b', 'h', 'r', 1)});
    $dbh->do(q{INSERT INTO feedback (id, iteration, target, body, created, updated, status) VALUES (4, 1, 'review', 'x', 1, 1, 'open')});

    my $before = time;
    $db->set_published(4);
    my ($published) = $dbh->selectrow_array('SELECT published FROM feedback WHERE id = 4');
    ok($published >= $before && $published <= time, 'published set to now');

    like(dies { $db->set_published(5) }, qr/No such feedback item: 5/, 'unknown item');
};

subtest flag_state => sub {
    my $db  = Review::Helper::DB->create("$tmp/marks.sqlite");
    my $dbh = $db->dbh;
    $dbh->do(q{INSERT INTO iteration (number, base, head, pin, created) VALUES (1, 'b', 'h', 'r1', 1), (2, 'b', 'h', 'r2', 1)});
    $dbh->do(q{INSERT INTO commit_entry (id, iteration, position, revision, subject, message) VALUES (1, 1, 1, 'a', 's', 'm'), (2, 2, 1, 'a', 's', 'm')});
    $dbh->do(q{INSERT INTO flag (id, note_id, commit_id, color, kind, sentence, created) VALUES (1, 'n', 1, 'red', 'note', 's', 1), (2, 'n', 2, 'red', 'note', 's', 1)});

    is($db->flag(2)->{commit_id}, 2,                                                                          'a flag by id');
    is($db->flag(3),              undef,                                                                      'no such flag');
    is($db->flag_by_note(2, 'n'), hash { field id => 2; field revision => 'a'; field topic => undef; etc() }, 'a flag by iteration and note id, with its entry');
    is($db->flag_by_note(2, 'x'), undef,                                                                      'or undef');

    $db->set_flag_seen(1, 'Ann', 1);
    $db->set_flag_seen(2, 'Ann', 1);
    $db->set_flag_seen(2, 'Bob', 1);
    $dbh->do(q{UPDATE flag_seen SET at = 9 WHERE reviewer = 'Ann'});
    $db->set_flag_seen(2, 'Ann', 1);
    is($db->flag_seen(2),                             [{flag => 2, reviewer => 'Ann', at => 9}, {flag => 2, reviewer => 'Bob', at => match qr/^\d+$/}], "the iteration's marks, oldest first; marking again keeps the time");
    is([map { $_->{reviewer} } @{$db->flag_seen(1)}], ['Ann'],                                                                                          'only that iteration');

    $db->set_flag_seen(2, 'Ann', 0);
    is([map { $_->{reviewer} } @{$db->flag_seen(2)}], ['Bob'], 'unmark removes only that reviewer');
    like(dies { $db->set_flag_seen(7, 'Ann', 1) }, qr/FOREIGN KEY/, 'a mark needs its flag');

    my $fb = $db->add_feedback(iteration => 1, target => 'review', body => 'b', reviewer => 'Ann');
    is($db->feedback($fb), hash { field id => $fb; field body => 'b'; field reviewer => 'Ann'; etc() }, 'a feedback row by id');
    is($db->feedback(99),  undef,                                                                       'or undef');
    $db->add_request(iteration => 1, kind => 'debate', target => 'review', reviewer => 'Bob');
    is([$dbh->selectrow_array('SELECT reviewer FROM feedback'), $dbh->selectrow_array('SELECT reviewer FROM request')], ['Ann', 'Bob'], 'feedback and requests record their reviewer');
    my $on = $db->add_feedback(iteration => 2, target => 'flag', flag => 'n', revision => 'a', body => 'why?');
    is($db->feedback($on)->{flag}, 'n', 'feedback on a flag keeps its note id');
};

# Only the format and its version are checked; files are never upgraded or
# changed. A file another build of the same version wrote opens as it is,
# read-only too, and fails later with SQLite errors if it differs.
subtest older_file => sub {
    my $path = "$tmp/older.sqlite";
    my $dbh  = Review::Helper::DB->create($path)->dbh;
    $dbh->do('ALTER TABLE section ADD COLUMN x_foo_bar TEXT');
    $dbh->do('ALTER TABLE flag DROP COLUMN detail');
    $dbh->do('DROP TABLE flag_seen');
    $dbh->disconnect;

    my $before = slurp($path);
    ok(lives { Review::Helper::DB->open($path)->review }, 'a file with another schema opens');
    ok(slurp($path) eq $before,                           'and is left byte for byte as it was');
    if ($>) {
        chmod(0444, $path) or die "chmod $path: $!";
        ok(lives { Review::Helper::DB->open($path)->review }, 'read-only too');
        chmod(0644, $path) or die "chmod $path: $!";
    }
};

done_testing;
