# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use File::Temp qw/tempdir/;
use TestRepo qw/make_repo commit_file write_file/;
use TestCLI qw/cli/;
use Review::Helper::DB;
use Review::Helper::Util qw/json_encode json_decode/;

my $tmp  = tempdir(CLEANUP => 1);
my $dir  = make_repo();
my $base = commit_file($dir, 'Base', 'a.txt' => "a\n");
commit_file($dir, 'One', 'a.txt' => "b\n");

my (undef, $file) = cli($dir, qw/build --base/, $base);
chomp($file);

my (undef, $out) = cli($dir, 'sheet', $file);
my $sheet     = json_decode($out);
my ($summary) = grep { $_->{type} eq 'summary' } @{$sheet->{items}};
my $total     = grep { !$_->{optional} } @{$sheet->{items}};

$summary->{fields} = {what => 'W', why => 'Y', how => 'H'};
write_file($tmp, 'sheet.json', json_encode($sheet));

my ($exit, $err);
($exit, $out, $err) = cli($dir, 'fill', $file, "$tmp/sheet.json");
is([$exit, $out, $err],                                                                 [0, "filled 1, remaining " . ($total - 1) . "\n", ''], 'prints the counts');
is(Review::Helper::DB->open($file)->dbh->selectrow_array('SELECT what FROM iteration'), 'W',                                                   'written');

subtest stdin => sub {
    my ($commit) = grep { $_->{type} eq 'commit' } @{$sheet->{items}};
    $commit->{fields} = {what => 'C'};
    my $json = json_encode({%$sheet, items => [$commit]});

    open(my $in, '<', \$json) or die $!;
    local *STDIN = $in;
    my ($exit, $out, $err) = cli($dir, 'fill', $file, '-');
    is([$exit, $out, $err], [0, "filled 1, remaining " . ($total - 1) . "\n", ''], "'-' reads standard input");
};

$summary->{fields} = {what => ''};
$summary->{rev}    = 'old';
write_file($tmp, 'bad.json', json_encode({%$sheet, items => [$summary, {id => 'x', fields => {a => 1}}]}));
($exit, $out, $err) = cli($dir, 'fill', $file, "$tmp/bad.json");
is($exit, 1,  'rejected sheet fails');
is($out,  '', 'nothing on stdout');
is(
    [split /\n/ => $err],
    ['review-helper fill: The sheet was rejected:', 'summary:1: stale revision; get a new sheet', 'x: unknown item'],
    'each problem on its own line',
);

write_file($tmp, 'junk.json', '{');
($exit, $out, $err) = cli($dir, 'fill', $file, "$tmp/junk.json");
like($err, qr/is not valid JSON/, 'invalid JSON');

($exit, $out, $err) = cli($dir, 'fill', $file, "$tmp/none.json");
like($err, qr/Cannot open '.*none\.json'/, 'missing sheet file');

($exit, $out, $err) = cli($dir, 'fill', $file);
like($err, qr/Usage: review-helper fill FILE SHEET/, 'two arguments');

done_testing;
