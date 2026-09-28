#!/usr/bin/env perl
#
# Row names that are not ASCII come back as the keys the caller used.
#
# fitted.values, residuals and the like are hashes keyed by row name.  Up to
# 0.3211 every model function copied a row name into a plain char * and stored
# it back with a positive length, which loses the UTF-8 flag: a name such as
# "\x{65e5}\x{672c}" came back as its six UTF-8 bytes, and the caller's own key
# did not find it.  A HoH key that fits in Latin-1 happened to survive, because
# perl stores it downgraded, but the same name given as a row.names or _row
# value did not.  The names are now held as UTF-8 throughout (rowname_dup() in
# LikeR.xs) and stored as UTF-8 keys, which perl downgrades where it can.
#
# R has no counterpart to test against: this is the Perl surface.  The three
# names cover the three cases -- a character string that fits in Latin-1, one
# that does not, and a Latin-1 *byte* string, which must come back as bytes,
# not upgraded to something the caller's key no longer matches.
#
# The data are arbitrary but deterministic; nothing here checks a fitted value,
# only which keys the result carries.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR qw(lm glm predict zerotrunc hurdle svyglm ivreg lmer aov);
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

my @names = ("caf\x{e9}", "\x{65e5}\x{672c}", "b\xe8s", map { "r$_" } 1 .. 17);
ok(utf8::is_utf8($names[1]) && !utf8::is_utf8($names[2]), 'the names are the kinds the header says');

my (%hoa, %hoh, @aoh);
for my $i (0 .. $#names) {
	my %r = (x => $i % 5 + 1, w => ($i * 7) % 11 + 1, g => $i % 4 ? 'a' : 'b',
	         s => 'S' . ($i % 4), pw => 1 + $i % 3);
	$r{y}  = 1 + 0.5 * $r{x} + ($i % 3) - 0.3 * $r{w};
	$r{k}  = ($i * 3) % 5;       # a count with zeros, for hurdle()
	$r{kp} = 1 + ($i * 3) % 5;   # one without, for zerotrunc()
	$r{b}  = ($i * 5) % 3 ? 1 : 0;
	push @{ $hoa{$_} }, $r{$_} for sort keys %r;
	$hoh{ $names[$i] } = {%r};
	push @aoh, { %r, _row => $names[$i] };
}
$hoa{'row.names'} = [@names];
my @shapes = (['HoA row.names', \%hoa], ['HoH', \%hoh], ['AoH _row', \@aoh]);

# Each function, and the row-keyed hashes it returns
my @calls = (
	['lm',        [qw(fitted.values residuals)],     sub { lm(formula => 'y ~ x + w', data => $_[0]) }],
	['glm',       [qw(fitted.values deviance.resid)], sub { glm(formula => 'b ~ x', family => 'binomial', data => $_[0]) }],
	['zerotrunc', [qw(fitted.values residuals)],     sub { zerotrunc(formula => 'kp ~ x', data => $_[0]) }],
	['hurdle',    [qw(fitted.values)],               sub { hurdle(formula => 'k ~ x | x', data => $_[0]) }],
	['svyglm',    [qw(fitted.values)],               sub { svyglm(formula => 'y ~ x', data => $_[0], weights => 'pw') }],
	['ivreg',     [qw(fitted.values residuals)],     sub { ivreg(formula => 'y ~ x | w', data => $_[0]) }],
	['lmer',      [qw(fitted.values)],               sub { lmer(formula => 'y ~ x + (1 | s)', data => $_[0]) }],
);
my @want = sort @names;
for my $c (@calls) {
	my ($fn, $hashes, $call) = @$c;
	for my $sh (@shapes) {
		my $r = $call->($sh->[1]);
		for my $h (@$hashes) {
			is_deeply([sort keys %{ $r->{$h} }], \@want, "$fn, $sh->[0]: $h is keyed by the caller's names");
		}
	}
}

# aov() names rows only from a HoH; a HoA or AoH is numbered
{
	my $r = aov(\%hoh, 'y ~ g');
	is_deeply([sort keys %{ $r->{'fitted.values'} }], \@want, "aov, HoH: fitted.values is keyed by the caller's names");
}

# predict() reads its newdata's row names with its own reader
{
	my $fit = lm(formula => 'y ~ x + w', data => \%hoa);
	for my $sh (@shapes) {
		my $p = predict($fit, $sh->[1]);
		is_deeply([sort keys %$p], \@want, "predict, $sh->[0]: result is keyed by the caller's names");
	}
}

# The copies are freed on every path, for each way a name arrives
for my $sh (@shapes) {
	my $d = $sh->[1];
	no_leaks_ok { lm(formula => 'y ~ x + w', data => $d) } "lm, $sh->[0]: no leak";
}

done_testing();
