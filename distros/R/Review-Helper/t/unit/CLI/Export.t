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

my (undef, $file) = cli($dir, qw/build --base/, $base, '--title', 'One');
chomp($file);
Review::Helper::DB->open($file)->dbh->do(q{UPDATE iteration SET what = ?}, undef, "Caf\x{e9}");

my ($exit, $out, $err) = cli($dir, 'export', $file);
is([$exit, $err], [0, ''], 'succeeds');
my $export    = json_decode($out);
my $iteration = $export->{tables}{iteration};
my %row       = map { ($iteration->{columns}[$_] => $iteration->{rows}[0][$_]) } 0 .. $#{$iteration->{columns}};
is($export->{format}, 'review-export', 'export printed');
is($row{what},        "Caf\x{e9}",     'UTF-8 encoded');

($exit, $out, $err) = cli($dir, 'export', $file, '--out', '.review-helper/one.json');
is([$exit, $out, $err], [0, '', ''], 'nothing printed with --out');
open(my $fh, '<', "$dir/.review-helper/one.json") or die $!;
is(json_decode(join '' => <$fh>), $export, 'written to the file, directory created');

($exit, $out, $err) = cli($dir, 'export');
like($err, qr/Usage: review-helper export FILE/, 'file required');

done_testing;
