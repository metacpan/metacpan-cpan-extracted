package Fixtures;

# The REGRESSION fixtures under t/fixtures, recorded by
# plan_crater/prototype/record.js from the JavaScript this engine was
# transliterated from. Each carries its own setup, so a field is rebuilt from
# the fixture alone: build($fx) turns that setup into the options
# Physics::Terrain->new takes. end_json spells an end state the way
# JSON.stringify did when the endSha was computed, key by key.

use strict;
use warnings;
use FindBin ();
use JSON::PP ();
use Physics::Terrain;

sub dir { return "$FindBin::Bin/fixtures" }

sub load {
	my ($name) = @_;
	my $path = dir() . "/$name.json";
	open my $fh, '<', $path or die "$path: $!";
	my $text = do { local $/; <$fh> };
	close $fh;
	return JSON::PP->new->decode($text);
}

sub names {
	opendir my $dh, dir() or die dir() . ": $!";
	my @names = sort map { s/\.json\z//r } grep { /\.json\z/ && !/^terrain-sha/ && !/^browser-/ } readdir $dh;
	closedir $dh;
	return @names;
}

sub all { return map { load($_) } names() }

sub options {
	my ($setup) = @_;
	my %o = (seed => $setup->{seed}, sculpt => $setup->{sculpt} || []);
	$o{gen} = $setup->{gen} if $setup->{gen};
	$o{wind} = $setup->{wind} if defined $setup->{wind};
	if (($setup->{place} || '') eq 'teams') {
		$o{place} = 'teams';
		$o{teams} = $setup->{teams};
		$o{per_team} = $setup->{perTeam};
	} else {
		$o{place} = 'explicit';
		$o{bodies} = $setup->{bodies};
	}
	return %o;
}

sub build {
	my ($fx) = @_;
	return Physics::Terrain->new(options($fx->{setup}));
}

sub end_json {
	my ($end) = @_;
	my $bodies = join ',', map { '[' . join(',', @$_) . ']' } @{ $end->{bodies} };
	my $health = join ',', @{ $end->{health} };
	return "{\"tick\":$end->{tick},\"bodies\":[$bodies],\"health\":[$health],\"craters\":$end->{craters}}";
}

1;
