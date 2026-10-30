#!/usr/bin/env perl
#
# The argparse-style help screens of lib/Stats/LikeR/Usage.pm: that every
# exported function has one, and that each keeps the layout Python's argparse
# gives its own help (CPython Lib/argparse.py, HelpFormatter, at a width of 80).
# Usage.pm's header comment states the layout, and where it departs from
# argparse's; this file is what holds a screen to it.
#
# Whether a given call-form error prints its function's screen is tested next
# to that function's other errors, in its own .t file.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR ();
use Stats::LikeR::Usage ();
use Test::More;

my %screen = %Stats::LikeR::Usage::SCREEN;
my %alias  = %Stats::LikeR::Usage::ALIAS;

# h() is how one reads a screen-less function's help, and takes any argument,
# so it has nothing to report a call-form error about.
my %no_screen = ( h => 1 );

for my $fn (@Stats::LikeR::EXPORT_OK) {
	next if $no_screen{$fn};
	if (exists $alias{$fn}) {
		ok(exists $screen{ $alias{$fn} }, "$fn is $alias{$fn}, which has a screen");
		next;
	}
	ok(exists $screen{$fn}, "$fn has a screen");
}

my %exported = map { $_ => 1 } @Stats::LikeR::EXPORT_OK;
for my $fn (sort keys %screen) {
	ok($exported{$fn}, "$fn, which has a screen, is exported");
	my $s = $screen{$fn};
	my @line = split /\n/, $s, -1;
	like($line[0], qr/\Ausage: \Q$fn\E\(/, "$fn: the screen opens with its usage line");
	like($s, qr/\n\n\z/, "$fn: the screen ends with one blank line") and unlike($s, qr/\n\n\n\z/, "$fn: and only one");
	my @wide = grep { length($_) > 80 } @line;
	is_deeply(\@wide, [], "$fn: no line is wider than 80 columns");
	unlike($s, qr/\t/, "$fn: no tabs");
	unlike($s, qr/[ ]\n/, "$fn: no trailing spaces");

	# usage continuation lines line up under the first argument, after
	# "usage: fn(", as argparse lines them up after "usage: prog "
	my $indent = length("usage: $fn(");
	my $i = 1;
	while ($i < @line && $line[$i] ne '') {
		like($line[$i], qr/\A {$indent}\S/, "$fn: usage line $i is indented under the first argument");
		$i++;
	}
	# then a blank line, the one-line description, and a blank line
	ok($i + 2 < @line && $line[$i] eq '' && $line[$i + 1] =~ /\A\S/ && $line[$i + 2] eq '',
		"$fn: a one-line description follows the usage");

	my @heads = grep { /\A\S.*:\z/ } @line[$i + 2 .. $#line];
	my %rank  = ('positional arguments:' => 0, 'options:' => 1, 'example:' => 2);
	my @bad   = grep { !exists $rank{$_} } @heads;
	is_deeply(\@bad, [], "$fn: only argparse's sections");
	my @order = map { $rank{$_} } grep { exists $rank{$_} } @heads;
	is_deeply(\@order, [ sort { $a <=> $b } @order ], "$fn: the sections are in order");
	ok((grep { $_ eq 'example:' } @heads), "$fn: there is an example");

	# an entry's help starts in column 26, or on the next line when its name
	# reaches column 24; the example's lines are code, and keep no columns
	my ($args) = $s =~ /\A.*?\n\n.*?\n\n(.*?)^example:/ms;
	for my $l (grep { /\A  \S.*? {2,}\S/ } split /\n/, $args) {
		my ($name, $help) = $l =~ /\A  (\S.*?) {2,}(\S.*)\z/;
		is(index($l, $help), 25, "$fn: '$name' has its help in column 26");
	}
}

# Called with nothing at all, every function dies with its own screen and the
# error on the last line -- the one call-form error each of them has, and the
# one xsubpp answered for a fixed-signature XSUB before it was made variadic.
# Left out: h(), which takes anything; rank(), uniq() and summary(), for which
# no data is a valid call; and map_cell() and p_adjust(), whose prototypes have
# perl refuse an empty call at compile time.
my %valid_empty = map { $_ => 1 } qw(h rank uniq summary map_cell p_adjust);
for my $fn (grep { !$valid_empty{$_} } @Stats::LikeR::EXPORT_OK) {
	my $code = \&{"Stats::LikeR::$fn"};
	my $err = do { local $@; eval { $code->(); 1 } ? '' : $@ };
	my $screen = Stats::LikeR::_usage_text($fn);
	ok(length($screen) && substr($err, 0, length $screen) eq $screen, "$fn(): dies with its screen")
		and like(substr($err, length $screen), qr/\A\w+: error: [^\n]+\n\z/, "$fn(): then the error, on one line");
}

# The error goes on the last line, under the screen, as ArgumentParser.error()
# puts it, and a name with no screen still raises its error.
is(eval { Stats::LikeR::_usage_error('df2h', 'a test'); 1 }, undef, '_usage_error dies');
is($@, $screen{df2h} . "df2h: error: a test\n", 'the screen, then the error on the last line');
is(eval { Stats::LikeR::_usage_error('aoh2h', 'a test'); 1 }, undef, 'an alias dies');
is($@, $screen{df2h} . "aoh2h: error: a test\n", 'with the screen of the function it is');
is(eval { Stats::LikeR::_usage_error('no_such_fn', 'a test'); 1 }, undef, 'a name without a screen dies');
is($@, "no_such_fn: error: a test\n", 'with the error alone');

done_testing();
