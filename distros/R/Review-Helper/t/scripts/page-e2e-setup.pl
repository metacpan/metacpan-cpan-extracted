#!/usr/bin/env perl
# Build a throwaway repository and a filled review that exercise the page,
# then serve it until killed. Prints the URL on standard output.
# t/integration/page-e2e.t drives the page against it with
# conformance/page-drive.mjs, at the top of the repository. With --topics, the
# review is instead a squashed one split into two topics.
#
# Usage: perl -Ilib t/scripts/page-e2e-setup.pl [--topics]
use v5.36;
use Cpanel::JSON::XS();
use File::Spec();
use FindBin();
use lib "$FindBin::Bin/../lib";

# The CLI loads subcommands lazily from inside the throwaway repository.
BEGIN {
    @INC = map { ref($_) ? $_ : File::Spec->rel2abs($_) } @INC;
}

use MIME::Base64 qw/decode_base64/;
use TestRepo qw/make_repo commit_file run_git/;
use TestCLI qw/cli/;
use TestSplit qw/fill_splits/;
use Review::Helper::CLI;
use Review::Helper::DB;
use Review::Helper::Journal;
use Review::Helper::VCS;
use Review::Helper::Sheet;

# A developer's own port-lease setting must not pick this server's port.
delete $ENV{REVIEW_HELPER_PORT_COMMAND};

# Leave through exit so the temporary repository is removed.
$SIG{TERM} = $SIG{INT} = sub { exit 0 };

my $FOO_1 = <<'PERL';
package Foo;
use v5.36;

sub new ($class, %args) {
    return bless {%args}, $class;
}
sub name ($self) {
    $self->{name};
}

1;

__END__

=head1 NAME

Foo - a thing

=head2 name

Returns the name.

=cut
PERL

my $FOO_2 = <<'PERL';
package Foo;
use v5.36;

sub new ($class, %args) {
    return bless {%args}, $class;
}
sub name ($self) {
    $self->{name} // 'anon';
}
sub greet ($self) {
    return <<"EOT";
Hello, @{[ $self->name ]}! <b>&amp;</b>
EOT
}

1;

__END__

=head1 NAME

Foo - a thing

=head2 name

Returns the name, or C<anon>.

=head2 greet

Returns a greeting.

=cut
PERL

my $UTIL_2 = <<'EOT';
/**
 * Join words with a separator.
 */
export function join(words, sep = ' ') {
    return words.join(sep);
}

export const shout = s => `${s.toUpperCase()}
!`;
EOT

# A module with several subs, each documented, long enough that its diff
# runs past the bottom of the window, with a constant between two subs.
my @BAR_SUBS = qw/start stop reset count total/;
my $BAR      = join '' => (
    "package Bar;\nuse v5.36;\n\n",
    (map { bar_sub($_) } @BAR_SUBS[0, 1]),
    "use constant LIMIT => 10;\n\n",
    (map { bar_sub($_) } @BAR_SUBS[2 .. $#BAR_SUBS]),
    "1;\n\n__END__\n\n=head1 NAME\n\nBar - a counter\n\n",
    (map { "=head2 $_\n\nThe $_ step.\n\n" } @BAR_SUBS),
    "=cut\n",
);

sub bar_sub($name) {
    my $body = join '' => map { "    my \$step$_ = \$self->{$name} + $_;\n" } 1 .. 8;
    return "sub $name (\$self, \@args) {\n$body    return \$step8;\n}\n\n";
}

my $UTIL_3 = join '' => (split /^/, $UTIL_2)[0 .. 5];
my $NOTES  = join '' => map { "Note $_.\n" } 1 .. 10;
my $TODO   = join '' => map { "- Task $_.\n" } 1 .. 4;
my $SVG_1  = qq{<svg xmlns="http://www.w3.org/2000/svg" width="40" height="40">\n<rect width="40" height="40" fill="red"/>\n</svg>\n};
my $SVG_2  = qq{<svg xmlns="http://www.w3.org/2000/svg" width="40" height="40">\n<circle cx="20" cy="20" r="18" fill="blue"/>\n</svg>\n};
my $PNG    = decode_base64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');

sub git_ok($dir, @args) { run_git($dir, @args); return }

sub cli_ok($dir, @args) {
    my ($exit, $out, $err) = cli($dir, @args);
    die "review-helper @args failed: $err" if $exit;
    chomp($out);
    return $out;
}

serve_topics() if ($ARGV[0] // '') eq '--topics';

my $dir = make_repo();
my %revision;

$revision{base} = commit_file($dir, 'Start the notes',               'COPYING'    => "Free to use.\n", 'notes.txt' => $NOTES, 'share/icon.svg' => $SVG_1, 'TODO.txt' => $TODO, 'old.bin' => join('' => map { chr } 0 .. 15));
$revision{c1}   = commit_file($dir, 'Add Foo, a logo and some data', 'lib/Foo.pm' => $FOO_1, 'share/logo.png' => $PNG,    'data.bin' => join('' => map { chr } 0 .. 15));
$revision{c2}   = commit_file($dir, 'Greet by name; add util.js',    'lib/Foo.pm' => $FOO_2, 'js/util.js'     => $UTIL_2, 'data.bin' => undef, 'share/icon.svg' => $SVG_2);

# Iteration 1 also has a commit that is gone by iteration 2.
$revision{old} = commit_file($dir, 'Add old.js', 'js/old.js' => "export const old = 1;\n");
my $file = cli_ok($dir, qw/build --base/, $revision{base}, '--title', 'Fixture review', '--source', 'https://example.com/org/repo/pull/7');
git_ok($dir, qw/reset -q --hard/, $revision{c2});

# The trailer is one long token, which must wrap at phone width.
$revision{c3} = commit_file($dir, "Drop shout\n\nClaude-Session: https://example.com/code/session_0123456789abcdefghijklmnopqrstuvwxyz", 'js/util.js' => $UTIL_3, 'TODO.txt' => undef, 'old.bin' => undef);

# docs branches off, with a changelog branch merged into it, then merges back.
git_ok($dir, qw/checkout -q -b docs/);
$revision{c4} = commit_file($dir, 'Add a README', 'README.md' => "# Foo\n\nFoo greets people by name.\n\nSee lib/Foo.pm.\n");
git_ok($dir, qw/checkout -q -b changelog/);
$revision{c5} = commit_file($dir, 'Start a changelog', 'Changes.md' => "# Changes\n\n- Added Foo.\n");
git_ok($dir, qw/checkout -q docs/);
git_ok($dir, qw/merge -q --no-ff -m/, "Merge branch 'changelog' into docs", 'changelog');
git_ok($dir, qw/checkout -q main/);
git_ok($dir, qw/merge -q --no-ff -m/, "Merge branch 'docs'", 'docs');
$revision{c7} = run_git($dir, qw/rev-parse HEAD/)   =~ s/\n//r;
$revision{c6} = run_git($dir, qw/rev-parse HEAD^2/) =~ s/\n//r;

git_ok($dir, qw/mv notes.txt/, 'docs-notes.txt');
git_ok($dir, qw/mv COPYING LICENSE/);
$revision{c8} = commit_file($dir, 'Move the notes',     'docs-notes.txt' => $NOTES . "Note 11.\n");
$revision{c9} = commit_file($dir, 'Add Bar, a counter', 'lib/Bar.pm'     => $BAR);

my $repo    = Review::Helper::VCS->detect($dir);
my $journal = Review::Helper::Journal->new(repo => $repo);
my $db      = Review::Helper::DB->open($file);

# Notes, and where the sheet places them: [commit, path, lines].
my @notes = (
    [
        {flag => 'red', kind => 'deviation', path => 'lib/Foo.pm', unit => 'greet', sentence => 'greet returns a heredoc with markup, which the spec did not ask for.', detail => 'The plan asked for a plain greeting. Callers render the greeting as HTML, so the markup is intentional. If plain text is wanted, drop the tags and the heredoc.'},
        [c2 => 'lib/Foo.pm', [10, 14]],
    ],
    [{flag => 'yellow', kind => 'note', path => 'js/util.js', sentence => 'shout spans two lines because of the template literal.', detail => 'The newline inside the literal is part of the output.'},      [c2 => 'js/util.js', [8, 9]]],
    [{flag => 'yellow', kind => 'assumption', path => 'lib/Foo.pm', sentence => 'Assumed nothing else reads the name field directly.'},                                                                      [c2 => 'lib/Foo.pm', undef]],
    [{flag => 'red', kind => 'self-review', path => 'data.bin', sentence => 'The binary file was added by mistake and is removed in the next commit.', detail => 'Self-review caught it after committing.'}, [c1 => undef, undef]],
    [
        {flag => 'yellow', kind => 'test-revealed', path => 'lib/Foo.pm', sentence => 'A test showed the constructor must copy the arguments.', detail => 'Blessing the hash of the caller let later changes leak back.'},
        [c1 => 'lib/Foo.pm', [5, 5]],
    ],
    [{flag => 'red',    kind => 'deviation', path => 'README.md',      sentence => 'The README was not in the plan.'},                [c4 => 'README.md',      undef]],
    [{flag => 'yellow', kind => 'note',      path => 'Changes.md',     sentence => 'The changelog starts with one entry.'},           [c5 => 'Changes.md',     [3,  3]]],
    [{flag => 'yellow', kind => 'note',      path => 'docs-notes.txt', sentence => 'The notes keep their history through the move.'}, [c8 => 'docs-notes.txt', [11, 11]]],
    [{flag => 'yellow', kind => 'note',      path => 'TODO.txt',       sentence => 'The TODO list goes; its tasks are done.'},        [c3 => 'TODO.txt',       [2,  3]]],

    # Line 5 is in sub new, which the commit did not change, so in none of
    # the sections the page lists.
    [{flag => 'yellow', path => 'lib/Foo.pm', sentence => 'The constructor is unchanged; callers still pass a name.'}, [c2 => 'lib/Foo.pm', [5, 5]]],
);
my %place      = map { ($_->[0]{sentence} => $_->[1]) } @notes;
my @note_ids   = map { $journal->add(%{$_->[0]}) } @notes;
my $greet_note = $note_ids[0];

# Journal entries, which iteration 2 takes as they are: one on a file the
# iteration changed, one on a file it did not.
$journal->add(
    kind     => 'test-revealed', path => 'lib/Foo.pm', unit => 'greet',
    sentence => 'The greeting tests needed a fresh object each.',
    detail   => "A shared object let one test's name leak into the next.\n\nEach test now builds its own.",
);
$journal->add(path => 'docs/plan.txt', sentence => 'The plan file was read, not changed.');

# Iteration 1 feedback, made before the rework.
$db->add_feedback(iteration => 1, target => 'line', revision => $revision{c2}, path => 'lib/Foo.pm', section_name => 'sub name', section_package => 'Foo', line => 8, side => 'new', body => 'Why default to anon?');
$db->add_feedback(iteration => 1, target => 'file', revision => $revision{old}, path => 'js/old.js', body => 'This file looks unused.');

cli_ok($dir, 'iterate', $file) eq '2' or die "iterate did not make iteration 2\n";

$db->add_feedback(iteration => 2, target => 'review',  body     => 'Please say why the logo is needed at all.', reviewer => 'Ann Other <ann@example.com>');
$db->add_feedback(iteration => 2, target => 'commit',  revision => $revision{c1},                               body     => 'Do not commit binaries.');
$db->add_feedback(iteration => 2, target => 'section', revision => $revision{c2},                               path     => 'lib/Foo.pm', section_name => 'sub greet', section_package => 'Foo', body => 'Could greet take a greeting word?');
$db->add_feedback(iteration => 2, target => 'line',    revision => $revision{c2},                               path     => 'lib/Foo.pm', line         => 8,           side            => 'old', body => 'The old accessor had no default; was anything relying on undef?');
$db->add_request(iteration => 2, kind => 'debate', target => 'file',    revision => $revision{c2}, path => 'lib/Foo.pm', note         => 'Is greet worth adding?');
$db->add_request(iteration => 2, kind => 'split',  target => 'file',    revision => $revision{c2}, path => 'js/util.js', note         => 'Split shout from join.');
$db->add_request(iteration => 2, kind => 'debate', target => 'section', revision => $revision{c2}, path => 'lib/Foo.pm', section_name => 'sub greet', section_package => 'Foo');
$db->add_request(iteration => 2, kind => 'debate', target => 'commit',  revision => $revision{c3}, note => 'Was dropping shout right?');

# Feedback a re-split moved to its file, keeping the section it was on.
$db->add_feedback(iteration => 2, target => 'file', revision => $revision{c2}, path => 'js/util.js', section_name => 'const shout', body => 'Is the newline in shout intended?');

my %subject = map { ($revision{$_} => $_) } keys %revision;

# The agent's split of each file, covering every line: subs with their POD,
# headings, and the lines around them. share/icon.svg is left unsplit, to
# show a file with no sections yet; docs-notes.txt is left whole.
my %splits = (
    'c1 lib/Foo.pm' => [
        {name => 'header',      package => 'Foo', lines => [[1,  2]]},
        {name => 'sub new',     package => 'Foo', lines => [[4,  6]]},
        {name => 'sub name',    package => 'Foo', lines => [[7,  9]], doc_lines => [[19, 23]]},
        {name => 'end',         package => 'Foo', lines => [[11, 13]]},
        {name => '=head1 NAME', package => 'Foo', lines => [[15, 18]]},
    ],
    'c2 lib/Foo.pm' => [
        {name => 'header',      package => 'Foo', lines => [[1,  2]]},
        {name => 'sub new',     package => 'Foo', lines => [[4,  6]]},
        {name => 'sub name',    package => 'Foo', lines => [[7,  9]],  doc_lines => [[24, 27]], old_lines => [[7, 9], [19, 23]]},
        {name => 'sub greet',   package => 'Foo', lines => [[10, 14]], doc_lines => [[28, 32]]},
        {name => 'end',         package => 'Foo', lines => [[16, 18]]},
        {name => '=head1 NAME', package => 'Foo', lines => [[20, 23]]},
    ],
    'c2 js/util.js'     => [{name => 'export function join', lines => [[4, 6]], doc_lines => [[1, 3]]}, {name => 'export const shout', lines => [[8, 9]]}],
    'c3 js/util.js'     => [{name => 'export function join', lines => [[4, 6]], doc_lines => [[1, 3]], old_lines => [[1, 3], [4, 6]]}],
    'c4 README.md'      => [{name => 'Foo',     lines => [[1, 5]]}],
    'c5 Changes.md'     => [{name => 'Changes', lines => [[1, 3]]}],
    'c8 docs-notes.txt' => [],
    'c9 lib/Bar.pm'     => [
        (map { +{name => "sub $BAR_SUBS[$_->[0]]", package => 'Bar', lines => [$_->[1]], doc_lines => [$_->[2]]} } [0, [4, 15], [74, 77]], [1, [16, 26], [78, 81]], [2, [30, 41], [82, 85]], [3, [42, 53], [86, 89]], [4, [54, 64], [90, 94]]),
        {name => 'header',             package => 'Bar', lines => [[1,  2]]},
        {name => 'use constant LIMIT', package => 'Bar', lines => [[28, 28]]},
        {name => 'end',                package => 'Bar', lines => [[66, 68]]},
        {name => '=head1 NAME',        package => 'Bar', lines => [[70, 73]]},
    ],
);
fill_splits($repo, $db, sub ($about) { $splits{"$subject{$about->{commit}} $about->{path}"} });

my %commit_text = (
    c1 => {what => 'Adds the `Foo` class and two assets.',                why => 'Foo is the base of the change.', how => 'A plain blessed hash.'},
    c3 => {what => 'Removes `shout`.',                                    why => 'Nothing used it.',               how => 'Deletes the export.'},
    c4 => {what => "Documents `Foo` for new readers.\n\nOne short page.", why => 'New readers asked.',             how => 'A README.'},
    c6 => {what => '- Brings in the changelog.',                          why => 'The docs branch needs it.',      how => 'A merge.'},
    c7 => {what => 'Merges the docs branch: a README and a changelog.',   why => 'Docs are done.',                 how => 'A merge.'},
);

my %file_text = (
    'c1 lib/Foo.pm'     => {what => 'Adds the `Foo` class with a constructor and a `name` accessor.', object_system => 'plain bless', paradigms => 'OOP'},
    'c1 share/logo.png' => {what => 'A placeholder logo.'},
    'c2 lib/Foo.pm'     => {what => 'Defaults the name to `anon` and adds `greet`.', object_system => 'plain bless', paradigms => 'OOP'},
    'c3 js/util.js'     => {what => 'Drops the unused `shout` helper from `Util::Shout::Helpers::For::Very::Loud::Greetings::And::More`.'},
    'c4 README.md'      => {what => 'Introduces `Foo`.'},
    'c9 lib/Bar.pm'     => {what => 'Adds the `Bar` counter with five steps.', object_system => 'plain bless', paradigms => 'OOP'},
);

my %section_text = (
    'c2 lib/Foo.pm sub name'  => "Falls back to `anon` when no name was given.\n\n- POD updated to match.",
    'c9 lib/Bar.pm sub start' => 'Starts the count from the stored value.',
    'c9 lib/Bar.pm sub stop'  => 'Stops the count and returns where it got to.',
);

my %order = (
    c1 => ['share/logo.png', 'lib/Foo.pm', 'data.bin'],
    c3 => ['js/util.js',     'TODO.txt',   'old.bin'],
    c4 => ['README.md'],
    c5 => ['Changes.md'],
    c8 => ['docs-notes.txt', 'LICENSE'],
    c9 => ['lib/Bar.pm'],
);

my @guide = (
    [{type => 'summary'},                                                                                                    [],                              'This change adds a small class and a helper script, then trims the helper.'],
    [{type => 'commit', commit => $revision{c1}},                                                                            [],                              'The first commit lays the groundwork: the class, a logo, and a data file.'],
    [{type => 'file', commit => $revision{c2}, path => 'lib/Foo.pm'},                                                        [],                              'In the second commit the Foo module gains a default name and a greeting.'],
    [{type => 'section', commit => $revision{c2}, path => 'lib/Foo.pm', section => {name => 'sub greet', package => 'Foo'}}, [['lib/Foo.pm', 'new', 11, 13]], 'The greeting builds its text with a heredoc.'],
    [{type => 'diff', commit => $revision{c2}, path => 'lib/Foo.pm', section => {name => 'sub name', package => 'Foo'}},     [['lib/Foo.pm', 'new', 8, 8]],   'The highlighted line now falls back to anon when no name was given.'],
    [{type => 'flag', flag => $greet_note},                                                                                  [],                              'The agent flagged the greeting because the markup was not in the plan.'],
    [{type => 'view', commit => $revision{c2}, path => 'js/util.js', lines => [1, 6]},                                       [['js/util.js', 'new', 4, 6]],   'The helper script joins words; the highlighted function does the work.'],
    [{type => 'diff', commit => $revision{c3}},                                                                              [['js/util.js', 'old', 8, 9]],   'The last commit drops the shout helper, shown highlighted on the old side.'],
    [{type => 'commit', commit => $revision{c5}},                                                                            [],                              'The changelog came in through a nested merge on the docs branch.'],
    [{type => 'view', commit => $revision{c8}, path => 'lib/Foo.pm', lines => [10, 14]},                                     [['lib/Foo.pm', 'new', 11, 13]], 'At the head the greeting reads the same; the highlighted heredoc holds the markup.'],

    # The highlight starts above the diff's first hunk, so its first line is
    # not on the page.
    [{type => 'diff', commit => $revision{c2}, path => 'lib/Foo.pm'}, [['lib/Foo.pm', 'new', 4, 8]], 'Back in the second commit, the constructor is unchanged above the new default.'],
);

my %feedback_reply = (
    'Why default to anon?'    => {status => 'addressed', response => 'The default is now documented in the POD.'},
    'Do not commit binaries.' => {status => 'declined',  response => 'The binary is removed in the next commit.'},
    'This file looks unused.' => {status => 'addressed', response => 'Removed.'},
);

my %debate_reply = (
    'Is greet worth adding?' => {
        case_for     => "Callers built the same greeting in three places.\n\n- one place to change the markup\n- tested once",
        case_against => "A heredoc with markup mixes presentation into the model.\n\n- a template would keep it out\n- the three callers could share a helper instead",
    },
);

my $fillers = {
    summary => sub ($about) {
        +{
            what => "A tiny change set used to exercise the page.\n\nIt covers:\n- added, modified, deleted and renamed files\n- an image and a binary\n- a commit with no reading order yet",
            why  => 'The page needs data that touches every rendering path.',
            how  => 'Small commits, two merges, and a second iteration.',
            note => "Drops `shout` after feedback.\n\n- Keeps `greet`.",
        };
    },
    commit  => sub ($about) { $commit_text{$subject{$about->{revision}}} },
    order   => sub ($about) { my $o = $order{$subject{$about->{commit}}}; $o ? {paths => $o} : undef },
    file    => sub ($about) { $file_text{"$subject{$about->{commit}} $about->{path}"} },
    section => sub ($about) { my $t = $section_text{"$subject{$about->{commit}} $about->{path} $about->{name}"}; $t ? {what => $t} : undef },
    note    => sub ($about) {
        my ($c, $path, $lines) = @{$place{$about->{sentence}}};
        return {commit => $revision{$c}, path => $path, lines => $lines};
    },
    feedback => sub ($about) { $feedback_reply{$about->{body}} },
    debate   => sub ($about) { defined($about->{note}) ? $debate_reply{$about->{note}} : undef },
    guide    => sub ($about) {
        +{
            steps => [
                map {
                    my ($target, $marks, $text) = @$_;
                    +{target => $target, highlight => [map { {path => $_->[0], side => $_->[1], lines => [$_->[2], $_->[3]]} } @$marks], commentary => $text};
                } @guide
            ],
        };
    },
    split => sub ($about) { undef },
};

my $sheet = Review::Helper::Sheet->new(repo => $repo, db => $db);
my $data  = $sheet->sheet;
for my $item (@{$data->{items}}) {
    my $fields = $fillers->{$item->{type}}->($item->{about}) or next;
    $item->{fields} = {%{$item->{fields}}, %$fields};
}
$sheet->fill($data);

# Placed notes are flags now; the agent turns the binary file's yellow, as
# the next commit removes the file.
$data = $sheet->sheet(all => 1);
my ($binary) = grep { $_->{type} eq 'flag' && $_->{about}->{sentence} =~ m/^The binary file/ } @{$data->{items}};
$binary->{fields} = {decision => 'recolor', color => 'yellow', reason => 'Removed in the next commit, as planned.'};
$sheet->fill({%$data, items => [$binary]});

my $flag_id = sub ($start) {
    my ($id) = $db->dbh->selectrow_array(q{SELECT flag.id FROM flag JOIN commit_entry ON commit_entry.id = flag.commit_id WHERE iteration = 2 AND sentence LIKE ?}, undef, "$start%");
    return $id;
};

# Another reviewer has seen the README flag.
$db->set_flag_seen($flag_id->('The README'), 'Bob Other', 1);

# A comment on the greet flag.
$db->add_feedback(iteration => 2, target => 'flag', flag => $greet_note, flag_sentence => $notes[0][0]{sentence}, revision => $revision{c2}, path => 'lib/Foo.pm', body => 'Is the markup tested?', reviewer => 'Ann Other <ann@example.com>');

# A flag on a file its commit did not change, as a squashed iteration
# carries one when the new squash no longer touches the file; the sheet
# places none.
my ($c9_id) = $db->dbh->selectrow_array('SELECT id FROM commit_entry WHERE iteration = 2 AND revision = ?', undef, $revision{c9});
$db->dbh->do(
    q{INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, kind, sentence, created, pending) VALUES ('carried-foo', ?, 'lib/Foo.pm', 3, 4, 'yellow', 'note', 'Bar copies the constructor of Foo.', ?, 1)},
    undef, $c9_id, time,
);

# A line flag on a binary, whose diff panel has no line table. The sheet
# rejects lines on a binary and carrying a flag widens them, but the format
# does not forbid the row, so a review file written by another tool can hold
# one; it stands in for any line flag whose panel shows no lines.
my ($c3_id) = $db->dbh->selectrow_array('SELECT id FROM commit_entry WHERE iteration = 2 AND revision = ?', undef, $revision{c3});
$db->dbh->do(
    q{INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, kind, sentence, created) VALUES ('gone-bin', ?, 'old.bin', 1, 1, 'yellow', 'note', 'The old blob goes with nothing reading it.', ?)},
    undef, $c3_id, time,
);

# A line flag on an image: its file tab opens with a picture and no line
# table, and the flag falls back to the file head once the panel settles.
my ($c1_id) = $db->dbh->selectrow_array('SELECT id FROM commit_entry WHERE iteration = 2 AND revision = ?', undef, $revision{c1});
$db->dbh->do(
    q{INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, kind, sentence, created) VALUES ('logo-line', ?, 'share/logo.png', 1, 1, 'yellow', 'note', 'The logo picture is a placeholder.', ?)},
    undef, $c1_id, time,
);

# Section feedback on a section its file does not show (an earlier split's):
# the summary lists it.
$db->add_feedback(iteration => 1, target => 'section', revision => $revision{c2}, path => 'lib/Foo.pm', section_name => 'sub gone', section_package => 'Foo', body => 'Was sub gone needed?');

# A last guide step on a section the page does not show, as a re-split after
# the guide was written leaves one: it shows its commentary only.
$db->dbh->do(
    q{INSERT INTO guide_step (iteration, position, target, highlight, commentary) VALUES (2, 12, ?, '[]', 'This section was split away after the guide was written.')},
    undef, Cpanel::JSON::XS->new->canonical->encode({type => 'section', commit => $revision{c2}, path => 'lib/Foo.pm', section => {name => 'sub gone', package => 'Foo'}}),
);

Review::Helper::CLI->run(serve => $file, '--reviewer', 'Tess Tester <tess@example.com>');

# A squashed review of a small codebase, split into two topics: the Perl
# backend and the frontend, with a flag and topic feedback in the second,
# feedback on the whole change from before the split, and a guide that plays
# the frontend topic, then its flag.
sub serve_topics() {
    my $dir  = make_repo();
    my $head = commit_file($dir, 'Land the app', 'lib/Foo.pm' => $FOO_2, 'lib/Bar.pm' => $BAR, 'js/util.js' => $UTIL_2, 'share/icon.svg' => $SVG_1);
    my $repo = Review::Helper::VCS->detect($dir);
    Review::Helper::Journal->new(repo => $repo)->add(flag => 'yellow', kind => 'note', path => 'js/util.js', sentence => 'join takes a separator.');
    my $file  = cli_ok($dir, qw/build --squash --title/, 'Topics review');
    my $db    = Review::Helper::DB->open($file);
    my $sheet = Review::Helper::Sheet->new(repo => $repo, db => $db);
    my $fill  = sub ($pick) {
        my $data = $sheet->sheet;
        my @items;
        for my $item (@{$data->{items}}) {
            my $fields = $pick->($item) or next;
            push @items => {%$item, fields => {%{$item->{fields}}, %$fields}};
        }
        $sheet->fill({%$data, items => \@items});
    };
    $db->add_feedback(iteration => 1, target => 'commit', revision => $head, body => 'Review the whole app.');

    $fill->(sub ($item) {
        $item->{type} eq 'topics' ? {topics => [{name => 'Perl backend', paths => ['lib/Bar.pm', 'lib/Foo.pm']}, {name => 'Frontend', paths => ['js/util.js', 'share/icon.svg']}]} : undef;
    });
    my %what = ('Perl backend' => 'The `Foo` and `Bar` modules.', Frontend => 'The page script and its icon.');
    $fill->(sub ($item) {
        return {what   => 'A small app.', why => 'To review it as it lands.', how => 'Two topics.'} if $item->{type} eq 'summary';
        return {what   => $what{$item->{about}->{topic}}, why => 'They land together.', how => 'Read them in order.'} if $item->{type} eq 'commit';
        return {commit => $head, path => 'js/util.js', lines => [4, 6]} if $item->{type} eq 'note';
        return undef;
    });
    my ($note) = $db->dbh->selectrow_array('SELECT note_id FROM flag');
    $fill->(sub ($item) {
        return undef unless $item->{type} eq 'guide';
        return {
            steps => [
                {target => {type => 'commit', commit => $head, topic => 'Frontend'}, commentary => 'The frontend.'},
                {target => {type => 'flag',   flag   => $note}, commentary => 'Its flag.'},
            ]
        };
    });
    $db->add_feedback(iteration => 1, target => 'commit', revision => $head, topic => 'Frontend', body => 'Is the icon final?');

    Review::Helper::CLI->run(serve => $file, '--reviewer', 'Tess Tester <tess@example.com>');
    exit 0;
}
