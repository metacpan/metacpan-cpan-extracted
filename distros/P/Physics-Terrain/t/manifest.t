#!perl
use 5.010;
use strict;
use warnings;
use File::Find ();
use Test::More;

# The stock manifest test needs Test::CheckManifest and skips when it is
# absent, which means it can go a whole life without running once. A test that
# says PASS because it could not do its job is worse than no test. This one
# does the job with core alone: a new file nobody listed, a listed file nobody
# shipped.

unless ($ENV{RELEASE_TESTING}) {
	plan skip_all => 'Author tests not required for installation';
}

plan tests => 2;

my $IGNORE = qr{
	\A (?: blib/ | \.git/ | \.build/ | _build/ | Install/ | Physics-Terrain-[\d.]+/ )
	| \A (?: Makefile | Makefile\.old | MANIFEST\.bak | pm_to_blib | Terrain\.c | Terrain\.bs | MYMETA\.(?:json|yml) ) \z
	| \.(?: o | bundle | so | dll | tar\.gz ) \z
	| ~ \z
}x;

open my $fh, '<', 'MANIFEST' or die "MANIFEST: $!";
my %listed;
while (my $line = <$fh>) {
	chomp $line;
	$line =~ s/\s+.*//;
	next unless length $line;
	$listed{$line} = 1;
}
close $fh;

my %present;
File::Find::find({ no_chdir => 1, wanted => sub {
	return unless -f;
	(my $rel = $File::Find::name) =~ s{^\./}{};
	return if $rel =~ $IGNORE;
	$present{$rel} = 1;
} }, '.');

my @unlisted = sort grep { !$listed{$_} } keys %present;
my @missing  = sort grep { !$present{$_} } keys %listed;

is_deeply \@unlisted, [], 'every shipped file is in the MANIFEST' or diag(join "\n", @unlisted);
is_deeply \@missing, [], 'every MANIFEST entry exists' or diag(join "\n", @missing);
