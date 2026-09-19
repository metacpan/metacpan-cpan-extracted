#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use Test::More;

# The engine never prints, reads, sleeps, calls rand or looks at a clock, and
# never touches floating point. A turn is a pure function of its inputs, so a
# log that cannot be replayed is not a log, and none of the sources of drift
# exist in the engine.
#
# A source scan, in the shape of Physics::Balls' t/08-no-io.t, over the C,
# the XS and the Perl. Comments and POD are stripped first.

plan tests => 3;

my $root = "$FindBin::Bin/..";

sub slurp {
	my ($path) = @_;
	open my $fh, '<', $path or die "$path: $!";
	my $code = do { local $/; <$fh> };
	close $fh;
	return $code;
}

subtest 'the C names no handle, no clock, no random and no float' => sub {
	plan tests => 1;
	my @caught;
	for my $path ("$root/pt_engine.c", "$root/include/pt_abi.h") {
		my $code = slurp($path);
		$code =~ s{/\*.*?\*/}{}gs;
		my $line = 0;
		for my $text (split /\n/, $code) {
			$line++;
			for my $bad (qw(printf fprintf puts fopen fread fwrite scanf getchar rand srand random time clock_gettime gettimeofday sleep usleep nanosleep sqrt sin cos atan2 floor pow)) {
				push @caught, "$path:$line calls $bad" if $text =~ /(?<![A-Za-z0-9_])\Q$bad\E\s*\(/;
			}
			push @caught, "$path:$line includes stdio" if $text =~ /^\s*#\s*include\s*<stdio\.h>/;
			push @caught, "$path:$line includes time.h" if $text =~ /^\s*#\s*include\s*<time\.h>/;
			push @caught, "$path:$line includes math.h" if $text =~ /^\s*#\s*include\s*<math\.h>/;
			push @caught, "$path:$line uses a float" if $text =~ /\b(?:double|float)\b/;
		}
	}
	is_deeply \@caught, [], 'pt_engine.c and pt_abi.h are pure and integer' or diag(join "\n", @caught);
};

subtest 'the XS names no handle, no clock and no random' => sub {
	plan tests => 1;
	my @caught;
	my $code = slurp("$root/Terrain.xs");
	$code =~ s{/\*.*?\*/}{}gs;
	my $line = 0;
	for my $text (split /\n/, $code) {
		$line++;
		next if $text =~ /^\s*#/;
		for my $bad (qw(printf fprintf puts fopen fread fwrite rand srand time sleep PerlIO_printf)) {
			push @caught, "Terrain.xs:$line calls $bad" if $text =~ /(?<![A-Za-z0-9_])\Q$bad\E\s*\(/;
		}
	}
	is_deeply \@caught, [], 'Terrain.xs is pure' or diag(join "\n", @caught);
};

subtest 'the Perl names no handle, no clock and no random' => sub {
	plan tests => 1;
	my @caught;
	for my $rel (qw(Terrain.pm Terrain/Snapshot.pm)) {
		my $path = "$root/lib/Physics/$rel";
		my $code = slurp($path);
		$code =~ s/^__END__.*\z//ms;
		$code =~ s/^\s*#.*$//mg;
		my $line = 0;
		for my $text (split /\n/, $code) {
			$line++;
			for my $bad (qw(STDIN STDOUT STDERR sleep)) {
				push @caught, "$path:$line names $bad" if $text =~ /\b\Q$bad\E\b/;
			}
			push @caught, "$path:$line calls rand" if $text =~ /(?<![a-z_])rand\s*[\(;]/;
			push @caught, "$path:$line reads the clock" if $text =~ /(?<![a-z_])time\s*[\(;]/;
			push @caught, "$path:$line prints" if $text =~ /\bprint\b/;
		}
	}
	is_deeply \@caught, [], 'no module reads a handle, prints, calls rand or looks at the clock' or diag(join "\n", @caught);
};
