# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use Cwd qw/abs_path/;
use File::Temp qw/tempdir/;

use TestRepo qw/make_repo commit_file run_git write_file/;
use TestCLI qw/cli/;
use Review::Helper::DB;

my $dir  = make_repo();
my $base = commit_file($dir, 'Base', 'a.txt' => "a\n");
my $head = commit_file($dir, 'One',  'a.txt' => "b\n");

my (undef, $file) = cli($dir, qw/build --base/, $base, '--title', 'One');
chomp($file);
cli($dir, 'export', $file, '--out', 'one.json');
my $json = "$dir/one.json";

my $clone = abs_path(tempdir(CLEANUP => 1));
run_git($clone, qw/clone -q/, $dir, '.');

my ($exit, $out, $err) = cli($clone, 'import', $json);
is([$exit, $err],                                                                     [0, ''],                                  'succeeds');
is($out,                                                                              "$clone/.git/review-helper/one.sqlite\n", 'prints the file, named after the JSON file');
is(Review::Helper::DB->open("$clone/.git/review-helper/one.sqlite")->review->{title}, 'One',                                    'review imported');

($exit, $out, $err) = cli($clone, 'import', $json, '--file', '.git/review-helper/two.sqlite');
is($exit, 1, 'fails');
like($err, qr/is already in this repository/, 'one copy per repository');

my $other = make_repo();
($exit, $out, $err) = cli($other, 'import', $json, '--file', '.git/review-helper/chosen.sqlite');
is($exit, 0,                                           'succeeds without the commits');
is($out,  "$other/.git/review-helper/chosen.sqlite\n", '--file chooses the path');
like($err, qr/Iteration 1: commit $head is not in this repository; fetch it/, 'missing commit named');

my $third = make_repo();
write_file($third, '.git/review-helper/one.sqlite', '');
($exit, $out, $err) = cli($third, 'import', $json);
is($exit, 1, 'fails');
like($err, qr/already exists/, 'never overwrites');

write_file($third, 'bad.json', '{');
($exit, $out, $err) = cli($third, 'import', 'bad.json');
like($err, qr/'bad\.json' is not valid JSON/, 'invalid JSON');

($exit, $out, $err) = cli($third, 'import');
like($err, qr/Usage: review-helper import JSON/, 'JSON required');

done_testing;
