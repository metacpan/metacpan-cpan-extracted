#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Digest::SHA ();

# The segments bit for bit. Each fixture carries segments_sha256, a digest over
# the big-endian bytes of every segment double, ball by ball in ascending id and
# segment by segment in time order, computed by the JavaScript that recorded it.
# The same digest here means the C engine produced the same doubles: the same
# operations in the same order, no fused multiply-add, sqrt correctly rounded.
#
# Tolerance is the contract (t/02); this is the target on top. A failure names
# the platform and the first differing number so it can be diagnosed rather
# than argued with.

use Physics::Balls;
use Presets;
use Config;

my @fixtures = Presets::fixtures();
plan tests => scalar @fixtures;

my %world = map { $_ => Presets::world_exact($_) } Presets::names();

# JSON has no negative zero, so the fixture (and the digest the JavaScript
# computed from its own JSON) carries +0 where the engine produced -0 for an
# acceleration along an axis the ball is not moving on. The digest here is over
# the JSON-visible value, which is also the only value the wire ever carries.
sub canon { my ($v) = @_; return $v == 0 ? 0 : $v }

sub digest_of {
	my ($segments) = @_;
	my $sha = Digest::SHA->new(256);
	for my $id (sort { $a <=> $b } keys %$segments) {
		for my $s (@{ $segments->{$id} }) {
			$sha->add(pack 'd>', canon($_)) for @$s;
		}
	}
	return $sha->hexdigest;
}

sub first_difference {
	my ($mine, $theirs) = @_;
	for my $id (sort { $a <=> $b } keys %$theirs) {
		my ($m, $t) = ($mine->{$id} || [], $theirs->{$id});
		return "ball $id has " . scalar(@$m) . ' segments here, ' . scalar(@$t) . ' recorded' if @$m != @$t;
		for my $i (0 .. $#$t) {
			for my $k (0 .. 7) {
				my ($a, $b) = (unpack('H*', pack 'd>', canon($m->[$i][$k])), unpack('H*', pack 'd>', canon($t->[$i][$k])));
				return "ball $id segment $i field $k: $a here, $b recorded ($m->[$i][$k] vs $t->[$i][$k])" if $a ne $b;
			}
		}
	}
	return 'no difference in the segments themselves';
}

for my $fx (@fixtures) {
	my $out = Physics::Balls->strike($world{ $fx->{table} }, layout => $fx->{layout}, %{ $fx->{shot} });
	my $mine = $out->error ? 'ERROR ' . $out->message : digest_of($out->segments);
	is $mine, $fx->{segments_sha256}, "$fx->{table}/$fx->{id}: the segments are bit-identical to the prototype's"
		or diag("on $Config{archname}, $Config{cc}: " . ($out->error ? $out->message : first_difference($out->segments, $fx->{segments})));
}
