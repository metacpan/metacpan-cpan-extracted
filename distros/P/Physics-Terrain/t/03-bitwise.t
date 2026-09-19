#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Digest::SHA ();

# The digests, bit for bit. Each fixture carries the SHA-256 the JavaScript
# computed over JSON.stringify of its end state, and over the packed mask
# before and after the turn; terrain-sha.json carries the mask digest of the
# default generator for seeds 1 to 100. The same digest here means the C
# produced the same integers: the same operations in the same order, every
# division floored, no product past 2^53 and none past 2^63.
#
# A failure names the fixture so it can be diagnosed rather than argued with.

use Physics::Terrain;
use Fixtures;

my @fixtures = Fixtures::all();
plan tests => 3 * @fixtures + 1;

for my $fx (@fixtures) {
	my $field = Fixtures::build($fx);
	is Digest::SHA::sha256_hex($field->mask), $fx->{maskBefore}, "$fx->{id}: the mask before the turn";
	my $out = $field->run_turn($fx->{active}, $fx->{inputs}, $fx->{shot});
	is Digest::SHA::sha256_hex(Fixtures::end_json($out->{end})), $fx->{endSha}, "$fx->{id}: the end-state SHA-256";
	is Digest::SHA::sha256_hex($field->mask), $fx->{maskAfter}, "$fx->{id}: the mask after the turn";
}

subtest 'the default generator over 100 seeds' => sub {
	my $recorded = Fixtures::load('terrain-sha');
	plan tests => 2 + scalar keys %{ $recorded->{shas} };
	is $recorded->{W}, 1280, 'recorded at 1280 wide';
	is $recorded->{H}, 640, 'recorded at 640 high';
	for my $seed (sort { $a <=> $b } keys %{ $recorded->{shas} }) {
		my $field = Physics::Terrain->new(seed => $seed, place => 'none');
		is Digest::SHA::sha256_hex($field->mask), $recorded->{shas}{$seed}, "seed $seed";
	}
};
