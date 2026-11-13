# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use TestRepo qw/make_repo commit_file/;
use TestCLI qw/cli/;
use Review::Helper::DB;
use Review::Helper::VCS;

my $dir  = make_repo();
my $base = commit_file($dir, 'Base',   'a.txt' => "a\n");
my $head = commit_file($dir, 'Change', 'a.txt' => "b\n");
my $hd   = Review::Helper::VCS->detect($dir)->state_dir;

my ($exit, $out, $err) = cli($dir, qw/build --base/, $base, qw/--title T --source/, 'https://example.com/pr/3');
is([$exit, $out, $err], [0, "$hd/main.sqlite\n", ''], 'prints the review file path');
is([@{Review::Helper::DB->open("$hd/main.sqlite")->review}{qw/title source/}], ['T', 'https://example.com/pr/3'], 'title and source stored');

($exit, $out, $err) = cli($dir, qw/build --base/, $base, '--head', $head, '--file', "$dir/x.sqlite");
is([$exit, $out, $err], [0, "$dir/x.sqlite\n", ''], 'explicit head and file');

($exit, $out, $err) = cli($dir, 'build');
is($exit, 1, 'base required');
like($err, qr/^review-helper build: Usage: review-helper build \[--base REV\].*\n--base is required unless --squash\.$/, 'usage');

($exit, $out, $err) = cli($dir, qw/build --base/, $base, 'extra');
like($err, qr/Usage: review-helper build/, 'no positional arguments');

($exit, $out, $err) = cli($dir, qw/build --base nope/);
is($exit, 1, 'unknown revision fails');
like($err, qr/Unknown revision 'nope'/, 'names the revision');

my $more = commit_file($dir, 'More', 'lib/b.txt' => "b\n");
($exit, $out, $err) = cli($dir, qw{build --squash --path lib --path *.txt --file}, "$dir/.git/squash.sqlite");
is([$exit, $out, $err], [0, "$dir/.git/squash.sqlite\n", ''], 'squashed build') or diag $err;
my $db = Review::Helper::DB->open("$dir/.git/squash.sqlite");
is(
    $db->dbh->selectrow_hashref('SELECT base, head, squashed, paths FROM iteration'),
    {base => Review::Helper::VCS->detect($dir)->empty_revision, head => $more, squashed => 1, paths => '["lib","*.txt"]'},
    'squash and paths stored, the empty revision as base',
);
is($db->dbh->selectall_arrayref('SELECT path FROM file_change ORDER BY path'), [['a.txt'], ['lib/b.txt']], 'matching files');

($exit, $out, $err) = cli($dir, qw/build --squash --base/, $base, qw/--path nothing/);
is($exit, 1, 'no matching files fails');
like($err, qr/No changes in .* under the given paths/, 'says why');

done_testing;
