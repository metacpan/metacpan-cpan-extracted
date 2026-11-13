# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use File::Temp qw/tempdir/;
use TestRepo qw/make_repo commit_file write_file/;
use TestCLI qw/cli/;
use Review::Helper::Util qw/json_encode json_decode/;

my $dir  = make_repo();
my $base = commit_file($dir, 'Base', 'a.txt' => "a\n");
commit_file($dir, "Caf\xc3\xa9", 'a.txt' => "b\n");

my (undef, $file) = cli($dir, qw/build --base/, $base);
chomp($file);

my ($exit, $out, $err) = cli($dir, 'sheet', $file);
is([$exit, $err], [0, ''], 'succeeds');
like($out, qr/^\{\n   "format" : "review-sheet",\n/, 'pretty JSON with sorted keys');

my $sheet = json_decode($out);
is([@$sheet{qw/format iteration/}], ['review-sheet', 1], 'sheet');
my ($commit) = grep { $_->{type} eq 'commit' } @{$sheet->{items}};
is($commit->{about}->{subject}, "Caf\x{e9}", 'UTF-8 encoded output');

my $rev = $commit->{rev};
my $tmp = tempdir(CLEANUP => 1);
write_file($tmp, 'sheet.json', json_encode({%$sheet, items => [{%$commit, fields => {what => 'W', why => 'Y', how => 'H'}}]}));
($exit, $out, $err) = cli($dir, 'fill', $file, "$tmp/sheet.json");
is([$exit, $err], [0, ''], 'commit filled');
(undef, $out) = cli($dir, 'sheet', $file);
ok(!(grep { $_->{id} eq $commit->{id} } @{json_decode($out)->{items}}), 'a filled item leaves the default sheet');

($exit, $out, $err) = cli($dir, qw/sheet --all/, $file);
is([$exit, $err], [0, ''], '--all succeeds');
my ($filled) = grep { $_->{id} eq $commit->{id} } @{json_decode($out)->{items}};
is($filled->{fields}, {what => 'W', why => 'Y', how => 'H'}, '--all lists it with its values');
isnt($filled->{rev}, $rev, 'and its current rev');

($exit, $out, $err) = cli($dir, 'sheet');
like($err, qr/Usage: review-helper sheet \[--all\] FILE/, 'file required');

done_testing;
