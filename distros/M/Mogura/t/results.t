use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use Mojo::File qw(path);
use Mojo::JSON qw(encode_json);
use lib 'lib';
use Mogura::Server::Results;
use Mogura::ResultStream;

my $root = tempdir(CLEANUP => 1);
my $source = path($root, 'grype.json');
my $results = Mogura::Server::Results->new(state => $root);
is_deeply(
    $results->row('syft', {name => '不明', version => 0, locations => [{}, {accessPath => '/lib'}]}),
    ['不明', '0', '', '', '/lib'],
    'Missing fields and locations leave literal package data intact'
);
my $file = $results->location('a' x 32, 'grype');
my @matches = map {
    {
        artifact => {name => '日本語 package-' . $_, version => "$_"},
        vulnerability => {
            id => "CVE-$_",
            severity => $_ % 2 ? 'High' : 'Critical',
            fix => {versions => ['2.0']}
        }
    }
} 1 .. 125;
$source->spurt(
    encode_json(
        {
            matches => \@matches,
            descriptor => {name => 'grype', db => {valid => 1}},
            ignoredMatches => [{unused => 'x' x 200000}]
        }
    )
);
my $revision = $results->revision($source);
ok($results->build($source, $file, 'grype', $revision), 'Build index from streaming input');
ok($results->ready($file, $revision), 'Index revision matches artifact');
my $page = $results->page($file, $revision, {});
is($page->{total}, 125, 'Full count');
is(scalar @{$page->{rows}}, 60, 'Only bounded window returned');
is($page->{rows}[0][1], '日本語 package-1', 'Unicode preserved');
is($page->{rows}[0][4], '2.0', 'Fix versions projected');
$page = $results->page($file, $revision, {start => 120});
is(scalar @{$page->{rows}}, 5, 'Final partial page');
$page = $results->page($file, $revision, {query => '日本語 PACKAGE-12'});
is($page->{count}, 7, 'Case folded substring search across entire artifact');
is($page->{total}, 125, 'Search preserves original total');
$page = $results->page($file, $revision, {column => 0});
is($page->{rows}[1][0], 'CVE-2', 'Numeric segments sort naturally');
$page = $results->page($file, $revision, {column => 0, descending => 1});
is($page->{rows}[0][0], 'CVE-125', 'Descending order covers entire result');
$page = $results->page($file, $revision, {column => 3});
is($page->{rows}[0][3], 'Critical', 'Severity has domain-specific order');
$page = $results->page($file, $revision, {query => "%' OR 1=1 --"});
is($page->{count}, 0, 'Search cannot change SQL or treat punctuation as wildcard');

# Structural checks alone cannot detect valid SQL edits; verify row content too.
my $db = $results->connect($file, 0);
my $metadata = $db->selectrow_hashref('SELECT * FROM metadata');
is(
    $metadata->{source_sha256},
    Digest::SHA::sha256_hex($source->slurp),
    'Source checksum covers exact JSON bytes'
);
ok(
    $results->verify($db, 125, $metadata->{rows_sha256}),
    'Committed rows pass readback verification'
);
$db->do("UPDATE rows SET c0 = 'changed' WHERE id = 0");
ok(!eval { $results->verify($db, 125, $metadata->{rows_sha256}); 1 },
    'Changed row content is rejected');
like($@, qr/content mismatch/, 'Content mismatch is diagnosed');
$db->do('DELETE FROM rows WHERE id = 0');
ok(!eval { $results->verify($db, 125, $metadata->{rows_sha256}); 1 }, 'Missing row is rejected');
like($@, qr/count mismatch/, 'Missing row is diagnosed');
$db->disconnect;
$results->build($source, $file, 'grype', $revision, force => 1);

my $scanner = 'Mogura::ResultStream';
my $envelope = $scanner->valid_artifact($source, 'grype');
is_deeply($envelope->{matches}, [], 'Validation retains no full result array');
is($envelope->{descriptor}{db}{valid}, 1, 'Validation keeps database identity');
ok(!exists $envelope->{ignoredMatches}, 'Unused large arrays discarded');
for my $invalid ('{"matches":[{}]', '{}{}', '{"matches":[{}],"descriptor":',
    '[]', '{"matches":{}}', '{"matches":[],"descriptor":{"name":"syft"}}')
{
    my $bad = path($root, 'bad.json')->spurt($invalid);
    ok(
        !eval { $scanner->valid_artifact($bad, 'grype'); 1 },
        "Reject invalid or incomplete envelope: $invalid"
    );
}
my $truncated = path($root, 'truncated.json')->spurt('{"matches":[{"artifact":{"name":"new"}}]');
ok(!eval { $results->build($truncated, $file, 'grype', $results->revision($truncated)); 1 },
    'Interrupted input cannot publish an index');
ok($results->ready($file, $revision), 'Failed replacement preserves existing index');
ok(!-e "$file.part", 'Failed temporary index cleaned up');
my $empty = path($root, 'empty.json')->spurt('{"matches":[]}');
my $new_revision = $results->revision($empty);
$results->build($empty, $file, 'grype', $new_revision);
is($results->page($file, $new_revision, {})->{count}, 0, 'Empty valid result supported');
ok(!$results->ready($file, $revision), 'Old artifact identity is not served');

# Exercise token boundaries, escapes, and a row larger than the read buffer.
my $large = path($root, 'large.json');
my $name = ('境界"\\' x 30000);
$large->spurt(
    encode_json({artifacts => [{name => $name}], descriptor => {name => 'syft'}, source => {}}));
my @rows;
Mogura::ResultStream->read($large, 'syft', sub { push @rows, $_[0] });
is($rows[0]{name}, $name, 'UTF-8 and escapes survive chunk boundaries');
is($scanner->valid_artifact($large, 'syft')->{descriptor}{name},
    'syft', 'Syft validation uses streaming envelope');
done_testing;
