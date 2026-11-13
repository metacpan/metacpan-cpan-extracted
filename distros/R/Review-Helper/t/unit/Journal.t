# Test origin: AI
use v5.36;
use utf8;
use Test2::V0;
use lib 't/lib';

use File::Temp qw/tempdir/;
use TestRepo qw/make_repo/;
use Review::Helper::VCS;
use Review::Helper::Journal;

my %note = (
    flag     => 'red',
    kind     => 'deviation',
    path     => 'lib/Foo.pm',
    sentence => 'Skips expiry when TTL is zero.',
);

subtest default_path => sub {
    my $dir     = make_repo();
    my $repo    = Review::Helper::VCS->detect($dir);
    my $journal = Review::Helper::Journal->new(repo => $repo);
    is($journal->path, "$dir/.git/review-helper/journal.jsonl", 'per-worktree path');

    my $id = $journal->add(%note);
    ok(-e $journal->path, 'file and directory created');
    is($journal->notes->[0]{id}, $id, 'note recorded');

    like(dies { Review::Helper::Journal->new }, qr/Either 'repo' or 'path' is required/, 'needs repo or path');
};

my $journal = Review::Helper::Journal->new(path => tempdir(CLEANUP => 1) . '/j/journal.jsonl');

subtest add_and_notes => sub {
    is($journal->notes, [], 'no file, no notes');

    my $id1 = $journal->add(%note);
    my $id2 = $journal->add(%note, flag => undef, kind => undef, unit => 'bar', snippet => 'return;', detail => "D\n✓");
    like($id1, qr/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-/, 'UUID v7 id');
    isnt($id1, $id2, 'distinct ids');

    is(
        $journal->notes,
        [
            {%note, id => $id1, created => match qr/^\d+$/, unit => undef, snippet => undef,   detail => undef},
            {%note, id => $id2, created => match qr/^\d+$/, flag => undef, kind    => 'other', unit   => 'bar', snippet => 'return;', detail => "D\n✓"},
        ],
        'notes in order, missing optional fields are null (no flag: a journal entry), a missing kind is other',
    );
    open(my $fh, '<:raw', $journal->path) or die $!;
    my @lines = <$fh>;
    is(scalar(@lines), 2, 'one line per note');
    my $raw = join '' => @lines;
    is(scalar(() = $raw =~ m/\xE2\x9C\x93/g), 1, 'non-ASCII text is stored as UTF-8, once');
    unlike($raw, qr/\xC3\xA2/, 'not encoded twice');
};

subtest validation => sub {
    like(dies { $journal->add(%note, flag     => 'green') },   qr/flag must be one of: yellow red/,                                                'bad color');
    like(dies { $journal->add(%note, flag     => '') },        qr/'flag' must not be empty/,                                                       'empty flag');
    like(dies { $journal->add(%note, severity => 2) },         qr/Unknown note fields: severity/,                                                  'no severity');
    like(dies { $journal->add(%note, kind     => 'concern') }, qr/kind must be one of: deviation assumption self-review test-revealed note other/, 'bad kind');
    like(dies { $journal->add(%note, path     => undef) },     qr/'path' is required/,                                                             'missing path');
    like(dies { $journal->add(%note, sentence => '') },        qr/'sentence' is required/,                                                         'empty sentence');
    like(dies { $journal->add(%note, detail   => '') },        qr/'detail' must not be empty/,                                                     'empty optional field');
    like(dies { $journal->add(%note, brief    => 'B.') },      qr/Unknown note fields: brief/,                                                     'unknown field');
    like(dies { $journal->add(%note, detail   => []) },        qr/'detail' must be a string/,                                                      'reference value');
    is(scalar(@{$journal->notes}), 2, 'nothing written on failure');
};

subtest entry_error => sub {
    my %ok = (id => 'n1', created => 5, kind => 'note', path => 'a.pm', sentence => 'S.');
    is($journal->entry_error(\%ok), undef, 'a note add could have written');
    is($journal->entry_error({%ok, severity => 2}),     undef,                                       'other fields are ignored');
    is($journal->entry_error({%ok, id       => {}}),    "'id' must be a non-empty string",           'an id that is not a string');
    is($journal->entry_error({%ok, id       => ''}),    "'id' must be a non-empty string",           'an empty id');
    is($journal->entry_error({%ok, created  => 'now'}), "'created' must be a time in epoch seconds", 'a bad time');
    is($journal->entry_error({%ok, kind     => undef}), "Note field 'kind' is required",             'no kind');
    like($journal->entry_error({%ok, kind => 'guess'}), qr/^Note kind must be one of: /, 'an unknown kind');
};

subtest remove => sub {
    my @ids = map { $_->{id} } @{$journal->notes};
    $journal->remove($ids[0], 'not-an-id');
    is([map { $_->{id} } @{$journal->notes}], [$ids[1]], 'removed one');
    $journal->remove($ids[1]);
    is($journal->notes, [], 'removed all');

    my $missing = Review::Helper::Journal->new(path => tempdir(CLEANUP => 1) . '/none.jsonl');
    ok(lives { $missing->remove('x') }, 'remove without a file');
};

subtest bad_lines => sub {
    my $bad = Review::Helper::Journal->new(path => tempdir(CLEANUP => 1) . '/journal.jsonl');
    my $one = $bad->add(%note);
    my $two = $bad->add(%note);
    open(my $fh, '>>', $bad->path) or die "Cannot open: $!";
    print $fh qq[{"id":"cut off\n[1]\n];
    close($fh);
    $bad->add(%note);

    my $notes;
    my $warnings = warnings { $notes = $bad->notes };
    is(scalar(@$notes), 3,                                                                            'the good notes still read');
    is($warnings,       [map { "Skipping line $_ of journal '${\ $bad->path}': not a note\n" } 3, 4], 'each bad line warned about by number');

    $warnings = warnings { $bad->remove($one) };
    is(scalar(@$warnings), 2, 'remove warns too');
    $warnings = warnings { $notes = $bad->notes };
    is([scalar(@$notes), $notes->[0]{id}], [2, $two], 'and removes the note asked for');
    like($warnings->[0], qr/Skipping line 2 /, 'keeping the bad lines, now earlier');
};

subtest cut_off_last_line => sub {
    my $cut = Review::Helper::Journal->new(path => tempdir(CLEANUP => 1) . '/journal.jsonl');
    my $one = $cut->add(%note);
    open(my $fh, '>>', $cut->path) or die "Cannot open: $!";
    print $fh '{"id":"cut';
    close($fh);
    my $two = $cut->add(%note);

    my $notes;
    my $warnings = warnings { $notes = $cut->notes };
    is([map { $_->{id} } @$notes], [$one, $two], 'a note added after a cut-off line is read');
    is(scalar(@$warnings),         1,            'only the cut-off line is skipped');
};

done_testing;
