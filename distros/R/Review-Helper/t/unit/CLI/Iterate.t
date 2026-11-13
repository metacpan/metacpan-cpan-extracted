# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use TestRepo qw/make_repo commit_file/;
use TestCLI qw/cli/;
use Review::Helper::DB;

my $dir  = make_repo();
my $base = commit_file($dir, 'Base', 'a.txt' => "a\n");
my $one  = commit_file($dir, 'One',  'a.txt' => "b\n");

my (undef, $file) = cli($dir, qw/build --base/, $base);
chomp($file);

my $two = commit_file($dir, 'Two', 'a.txt' => "c\n");
my ($exit, $out, $err) = cli($dir, 'iterate', $file);
is([$exit, $out, $err], [0, "2\n", ''], 'prints the iteration number');

($exit, $out, $err) = cli($dir, 'iterate', $file, '--base', $one, '--head', $two);
is([$exit, $out, $err], [0, "3\n", ''], 'explicit range');

my $db = Review::Helper::DB->open($file);
is($db->dbh->selectall_arrayref('SELECT number, base, head FROM iteration ORDER BY number'), [[1, $base, $one], [2, $base, $two], [3, $one, $two]], 'iterations');

($exit, $out, $err) = cli($dir, 'iterate');
like($err, qr/Usage: review-helper iterate FILE/, 'file required');

($exit, $out, $err) = cli($dir, 'iterate', "$dir/none.sqlite");
like($err, qr/No such review file/, 'missing file');

(undef, my $squashed) = cli($dir, qw/build --squash --path a.txt/);
chomp($squashed);
my $three = commit_file($dir, 'Three', 'a.txt' => "d\n", 'b.txt' => "b\n");
($exit, $out, $err) = cli($dir, 'iterate', $squashed);
is([$exit, $out, $err], [0, "2\n", ''], 'iterate a squashed review');
my $sq = Review::Helper::DB->open($squashed)->dbh;
is($sq->selectrow_hashref('SELECT squashed, paths, head FROM iteration WHERE number = 2'),                                      {squashed => 1, paths => '["a.txt"]', head => $three}, 'squash and paths kept');
is($sq->selectall_arrayref('SELECT f.path FROM file_change f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = 2'), [['a.txt']],                                           'still limited');

done_testing;
