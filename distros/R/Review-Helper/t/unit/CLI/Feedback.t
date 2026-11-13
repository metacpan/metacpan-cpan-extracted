# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use TestRepo qw/make_repo commit_file/;
use TestCLI qw/cli/;
use Review::Helper::DB;
use Review::Helper::Util qw/json_decode/;

my $dir  = make_repo();
my $base = commit_file($dir, 'Base', 'a.txt' => "a\n");
commit_file($dir, 'One', 'a.txt' => "b\n");

my (undef, $file) = cli($dir, qw/build --base/, $base);
chomp($file);

my $dbh = Review::Helper::DB->open($file)->dbh;
$dbh->do(q{INSERT INTO feedback (iteration, target, body, created, updated, status) VALUES (1, 'review', ?, 1, 1, 'open')}, undef, "Caf\x{e9}?");
$dbh->do(q{INSERT INTO feedback (iteration, target, body, created, updated, status) VALUES (1, 'review', 'Old.', 1, 1, 'declined')});

my ($exit, $out, $err) = cli($dir, 'feedback', $file);
is([$exit, $err], [0, ''], 'succeeds');
my $all = json_decode($out);
is([@$all{qw/format iteration/}],            ['review-feedback', 1],      'export');
is([map { $_->{body} } @{$all->{feedback}}], ["Caf\x{e9}?",      'Old.'], 'all feedback, UTF-8 encoded');

($exit, $out) = cli($dir, 'feedback', '--open', $file);
is([map { $_->{body} } @{json_decode($out)->{feedback}}], ["Caf\x{e9}?"], '--open');

my $head = Review::Helper::DB->open($file)->latest_iteration->{head};
my $body = "Caf\x{e9}?\n\n  two \x{1F600}\n";
$dbh->do(q{INSERT INTO feedback (iteration, target, revision, path, line, side, body, created, updated, status) VALUES (1, 'line', ?, 'a.txt', 1, 'new', ?, 1, 1, 'open')}, undef, $head, $body);

($exit, $out, $err) = cli($dir, 'feedback', '--publish', $file);
is([$exit, $err], [0, ''], '--publish succeeds');
my $publish = json_decode($out);
is([@$publish{qw/format head/}], ['review-publish', $head], 'publish list');
is(
    $publish->{items},
    [
        {id => 1, text => "Caf\x{e9}?", anchor => undef,                                       fallback => undef},
        {id => 3, text => $body,        anchor => {path => 'a.txt', line => 1, side => 'new'}, fallback => "`a.txt:1` (commit " . substr($head, 0, 7) . ")\n\n$body"},
    ],
    'open, unposted items: text, anchor and fallback, UTF-8 encoded',
);

($exit, $out) = cli($dir, 'feedback', '--publish', $file, 2);
is([map { $_->{id} } @{json_decode($out)->{items}}], [2], '--publish with ids');

($exit, $out, $err) = cli($dir, 'feedback', '--publish', $file, 'x');
like($err, qr/No such feedback item: x/, 'unknown id');

($exit, $out, $err) = cli($dir, 'feedback', '--publish', '--open', $file);
like($err, qr/--open and --publish do not combine/, '--open and --publish');

($exit, $out, $err) = cli($dir, 'feedback', $file, 2);
like($err, qr/Usage: review-helper feedback FILE/, 'ids only with --publish');

($exit, $out, $err) = cli($dir, 'feedback');
like($err, qr/Usage: review-helper feedback FILE/, 'file required');

done_testing;
