#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use Test::More;

# The engine never prints, reads, sleeps, calls rand or looks at a clock. A
# game is a pure function of its inputs, so a log that cannot be replayed is
# not a log, and none of the sources of drift exist in the engine.
#
# A source scan, in the shape of Game::Dominoes' t/21-no-io.t, over the C and
# the Perl. Comments and POD are stripped first: the C's header comment names
# printf in prose, and this file names rand in its own.

plan tests => 2;

my $root = "$FindBin::Bin/..";

subtest 'the C names no handle, no clock and no random' => sub {
	plan tests => 1;
	my @caught;
	for my $path ("$root/pb_engine.c", "$root/include/pb_abi.h") {
		open my $fh, '<', $path or die "$path: $!";
		my $code = do { local $/; <$fh> };
		close $fh;
		$code =~ s{/\*.*?\*/}{}gs;
		my $line = 0;
		for my $text (split /\n/, $code) {
			$line++;
			for my $bad (qw(printf fprintf puts fopen fread fwrite scanf getchar rand srand random time clock_gettime gettimeofday sleep usleep nanosleep)) {
				push @caught, "$path:$line calls $bad" if $text =~ /(?<![A-Za-z0-9_])\Q$bad\E\s*\(/;
			}
			push @caught, "$path:$line includes stdio" if $text =~ /^\s*#\s*include\s*<stdio\.h>/;
			push @caught, "$path:$line includes time.h" if $text =~ /^\s*#\s*include\s*<time\.h>/;
		}
	}
	is_deeply \@caught, [], 'pb_engine.c and pb_abi.h are pure' or diag(join "\n", @caught);
};

subtest 'the Perl names no handle, no clock and no random' => sub {
	plan tests => 1;
	my @caught;
	for my $rel (qw(Balls.pm Balls/Engine.pm Balls/World.pm Balls/Table.pm Balls/Strike.pm Balls/Outcome.pm Balls/Ball.pm Balls/Error.pm)) {
		my $path = "$root/lib/Physics/$rel";
		open my $fh, '<', $path or die "$path: $!";
		my $code = do { local $/; <$fh> };
		close $fh;
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
