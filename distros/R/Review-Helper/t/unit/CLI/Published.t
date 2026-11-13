# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use TestRepo qw/make_repo/;
use TestCLI qw/cli/;
use Review::Helper::DB;
use Review::Helper::VCS;

my $dir  = make_repo();
my $repo = Review::Helper::VCS->detect($dir);
my $file = $repo->state_dir . '/one.sqlite';

my $db  = Review::Helper::DB->create($file);
my $dbh = $db->dbh;
$dbh->do(q{INSERT INTO iteration (number, base, head, pin, created) VALUES (1, 'b', 'h', 'r', 1)});
my $insert = $dbh->prepare(q{INSERT INTO feedback (id, iteration, target, body, created, updated, status) VALUES (?, 1, 'review', ?, 1, 1, 'open')});
$insert->execute(1, 'first');
$insert->execute(2, 'second');

sub published($id) { ($dbh->selectrow_array('SELECT published FROM feedback WHERE id = ?', undef, $id))[0] }

is(published(1), undef, 'not published to start');

my $before = time;
my ($exit, $out, $err) = cli($dir, 'published', $file, 2);
is([$exit, $out, $err], [0, '', ''], 'published prints nothing');
ok(published(2) >= $before && published(2) <= time, 'published time set to now');
is(published(1), undef, 'other items untouched');

($exit, undef, $err) = cli($dir, 'published', $file, 3);
is($exit, 1, 'unknown id fails');
like($err, qr/No such feedback item: 3/, 'unknown id named');

(undef, undef, $err) = cli($dir, 'published', $file, 'x');
like($err, qr/Feedback ID must be a positive integer, got 'x'/, 'id must be an integer');

(undef, undef, $err) = cli($dir, 'published', $file);
like($err, qr/Usage: review-helper published FILE ID/, 'needs a file and an id');

(undef, undef, $err) = cli($dir, 'published', "$dir/none.sqlite", 1);
like($err, qr/No such review file/, 'missing file');

done_testing;
