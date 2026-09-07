#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use File::Temp ();
use Digest::SHA qw(sha256_hex);
use Encode ();
use Punk::Challenge::Token ();

# The only witness for the JavaScript. If node is on the path, the file is
# loaded outside a browser, a hundred fixed strings are hashed through its
# SHA-256 and compared against Digest::SHA, and an eight-bit puzzle issued
# by Token is solved by it and verified by Token. Without node, a skip that
# says so. No browser is involved: this proves the arithmetic, and only a
# phone proves the timing table.

my $node;
for my $dir (File::Spec->path) {
    my $p = File::Spec->catfile($dir, 'node');
    if (-x $p) { $node = $p; last }
}
plan skip_all => 'node is not on the path; the solver is untested here' unless $node;

my $json_pp = eval { require JSON::PP; 1 };
plan skip_all => 'JSON::PP required' unless $json_pp;

my $js = $INC{'Punk/Challenge.pm'};
$js =~ s{Challenge\.pm\z}{Plugin/Challenge/challenge.js};
ok(-f $js, "the solver is at $js");

# The harness: load the file, then read one JSON document from stdin and
# answer with one.
my $harness = <<'JS';
require(process.argv[2]);
const P = globalThis.PunkChallenge;
let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (d) => { input += d; });
process.stdin.on('end', () => {
  const req = JSON.parse(input);
  const out = {
    digests: req.strings.map((s) => P.sha256hex(s)),
    solution: P.solveSync(req.puzzle),
  };
  process.stdout.write(JSON.stringify(out));
});
JS

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $hfile = File::Spec->catfile($dir, 'harness.js');
open my $hfh, '>', $hfile or die "$hfile: $!";
print $hfh $harness;
close $hfh;

# A hundred fixed strings: every length across the two padding boundaries,
# and a few that are not ASCII, so TextEncoder's UTF-8 is what is hashed.
my @strings = (
    (map { 'a' x $_ } 0 .. 70),
    (map { join '', map { chr(33 + ($_ * 7) % 90) } 0 .. $_ } 100, 119, 120, 127, 128, 200),
    'The quick brown fox jumps over the lazy dog',
    'abc',
    'caf' . chr(0xe9),
    chr(0x263a) . ' smile',
    (map { "v1.1725600000.16.k3x-2f.Zm9vYmFyYmF6cXV4AAAAAAAA.$_" } 0 .. 20),
);
@strings = @strings[0 .. 99];
is(scalar @strings, 100, 'a hundred strings');

my %cfg = ( secret => 'k', bits => 8 );
my $S = '192.0.2.0/24';
my $puzzle = Punk::Challenge::Token->issue(\%cfg, $S);

my $in = JSON::PP->new->utf8->encode({ strings => \@strings, puzzle => $puzzle });
my $ifile = File::Spec->catfile($dir, 'in.json');
open my $ifh, '>:raw', $ifile or die "$ifile: $!";
print $ifh $in;
close $ifh;

my $out = do {
    local $/;
    open my $ph, '-|', "$node \Q$hfile\E \Q$js\E < \Q$ifile\E" or die "node: $!";
    <$ph>;
};
ok(defined $out && length $out, 'node answered') or BAIL_OUT('no output from node');
my $got = JSON::PP->new->utf8->decode($out);

my $bad = 0;
for my $i (0 .. $#strings) {
    my $want = sha256_hex(Encode::encode_utf8($strings[$i]));
    next if $got->{digests}[$i] eq $want;
    $bad++;
    diag("string $i (" . length($strings[$i]) . " chars): got $got->{digests}[$i], want $want");
}
is($bad, 0, 'every one of the hundred digests agrees with Digest::SHA');

like($got->{solution}, qr/^\Q$puzzle\E\.\d+\z/, 'the solver produced a solution');
is(scalar Punk::Challenge::Token->verify(\%cfg, $S, $got->{solution}), 8,
    '  and Token verifies it');

done_testing;
