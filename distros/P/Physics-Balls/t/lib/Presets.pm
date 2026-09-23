package Presets;

# The two tables the prototype's fixtures were recorded on, in metres. The
# numbers are the site's business (plan_pool_snooker/00-overview.md pins them);
# they are here so the dist's tests are self-contained.
#
# world_exact loads the geometry the JavaScript computed, double for double,
# from t/fixtures/geometry-*.json, because Math.cos in V8 and cos in libm may
# differ in the last bit and the bitwise test must start from identical walls.
# world_built builds it with Physics::Balls::Table, for the tolerance tests.

use strict;
use warnings;
use FindBin ();
use JSON::PP ();
use Physics::Balls;
use Physics::Balls::Table;
use Physics::Balls::World;

my %DESC = (
	pool => {
		L => 2.540, W => 1.270, R => 0.028575,
		corner => { mouth => 0.1175, jaw_deg => 142, shelf => 0.041 },
		side   => { mouth => 0.1302, jaw_deg => 104, shelf => 0.008 },
		mu => { s => 0.2, r => 0.02, sp => 0.044 },
		e  => { bb => 0.95, c => 0.8, cf => 0.2, rc => 0.7 },
		vmax => 8, g => 9.81,
	},
	snooker => {
		L => 3.569, W => 1.778, R => 0.02625,
		corner => { mouth => 0.086, jaw_deg => 142, shelf => 0.030 },
		side   => { mouth => 0.095, jaw_deg => 104, shelf => 0.008 },
		mu => { s => 0.2, r => 0.015, sp => 0.044 },
		e  => { bb => 0.95, c => 0.8, cf => 0.2, rc => 0.7 },
		vmax => 8, g => 9.81,
	},
);

sub names { return qw/pool snooker/ }

sub desc { my ($name) = @_; return $DESC{$name} }

sub table {
	my ($name) = @_;
	my $d = $DESC{$name} or die "Presets: no table $name";
	return Physics::Balls::Table->new(L => $d->{L}, W => $d->{W}, R => $d->{R}, corner => $d->{corner}, side => $d->{side});
}

sub constants {
	my ($name) = @_;
	my $d = $DESC{$name};
	return (mu => $d->{mu}, e => $d->{e}, vmax => $d->{vmax}, g => $d->{g});
}

sub world_built {
	my ($name) = @_;
	return Physics::Balls::World->from_table(table($name), constants($name));
}

sub fixture_dir { return "$FindBin::Bin/fixtures" }

sub read_json {
	my ($file) = @_;
	open my $fh, '<', $file or die "$file: $!";
	my $text = do { local $/; <$fh> };
	close $fh;
	return JSON::PP->new->decode($text);
}

sub hex_to_nv { my ($h) = @_; return unpack 'd>', pack 'H*', $h }

# Events an instant apart are one instant: the engine orders two rolls at the
# same time by which queue entry came first, and a build whose doubles differ
# in the last place orders them the other way. Before an index-by-index
# comparison each run of events within $tol of its neighbour is sorted by kind
# and participants, on both sides the same, so the contract is the order of
# what happens and not the order of what happens at once.
sub settle_ties {
	my ($events, $tol) = @_;
	my (@out, @run);
	my $flush = sub {
		push @out, sort { join("\0", @$a[1 .. $#$a]) cmp join("\0", @$b[1 .. $#$b]) } @run;
		@run = ();
	};
	for my $e (@$events) {
		$flush->() if @run && abs($e->[0] - $run[-1][0]) >= $tol;
		push @run, $e;
	}
	$flush->();
	return \@out;
}

# The marks that compare against recorded doubles hold only where the compiler
# rounds every operation to a double; a build left on the x87 unit lands a few
# ulps off in the first segment and a collision cascade carries it anywhere.
# The reason to skip those marks, or nothing.
sub wide_doubles {
	my $m = Physics::Balls->float_eval_method;
	return $m > 0 ? "FLT_EVAL_METHOD is $m: this build evaluates a double wider than a double, and the fixtures were recorded at 64 bits" : '';
}

sub geometry {
	my ($name) = @_;
	return read_json(fixture_dir() . "/geometry-$name.json");
}

sub world_exact {
	my ($name) = @_;
	my $g = geometry($name);
	my $w = $g->{world};
	my $hx = $g->{hex};
	my $conv = sub {
		my ($rows, $hexrows) = @_;
		return [ map { my $i = $_; [ map { hex_to_nv($hexrows->[$i][$_]) } 0 .. $#{ $rows->[$i] } ] } 0 .. $#$rows ];
	};
	my $d = $DESC{$name};
	return Physics::Balls::World->new(
		L => hex_to_nv($hx->{L}), W => hex_to_nv($hx->{W}), R => hex_to_nv($hx->{R}),
		walls => $conv->($w->{walls}, $hx->{walls}),
		noses => $conv->($w->{noses}, $hx->{noses}),
		gates => $conv->($w->{gates}, $hx->{gates}),
		constants($name),
	);
}

sub fixtures {
	my $dir = fixture_dir();
	opendir my $dh, $dir or die "$dir: $!";
	my @files = sort grep { /\.json\z/ && !/^geometry-/ } readdir $dh;
	closedir $dh;
	return map { read_json("$dir/$_") } @files;
}

1;
