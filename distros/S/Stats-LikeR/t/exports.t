#!/usr/bin/env perl
#
# What `use Stats::LikeR` puts in the caller's package. Nothing by default (up
# to 0.3431 every function was exported, over the caller's own min, max, sum,
# filter, merge and the rest); a name asked for; or every name with ':all'.
# Exporter behavior with no R or Python equivalent, so these cases are
# hand-written. Each import runs in its own package, so one cannot satisfy
# another's check.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;

my @all = do { require Stats::LikeR; @Stats::LikeR::EXPORT_OK };

sub imported {
	my ($pkg) = @_;
	no strict 'refs';
	return [ grep { defined &{"${pkg}::$_"} } @all ];
}

package Exports::Default; use Stats::LikeR;
package Exports::Empty;   use Stats::LikeR ();
package Exports::Named;   use Stats::LikeR qw(mean sd);
package Exports::All;     use Stats::LikeR qw(:all);
package Exports::Own;
sub min { 'mine' }
use Stats::LikeR qw(max);
package main;

is_deeply(imported('Exports::Default'), [], 'use Stats::LikeR imports nothing');
is_deeply(imported('Exports::Empty'),   [], 'use Stats::LikeR () imports nothing');
is_deeply([ sort @{ imported('Exports::Named') } ], [qw(mean sd)],
	'a list imports those names and no others');
is_deeply([ sort @{ imported('Exports::All') } ], [ sort @all ], ':all imports every function');
is(scalar @{ $Stats::LikeR::EXPORT_TAGS{all} }, scalar @all, ':all is exactly @EXPORT_OK');
is_deeply(\@Stats::LikeR::EXPORT, [], '@EXPORT is empty');

is(Exports::Own::min(), 'mine', "a caller's own min() is left alone");
is(Exports::Own::max([1, 3, 2]), 3, 'while the max() it asked for is imported');
is(Exports::Named::mean([1, 2, 3]), 2, 'an imported function works');
is(Stats::LikeR::median([3, 1, 2]), 2, 'a fully qualified call needs no import');

eval "package Exports::Bad; use Stats::LikeR qw(no_such_function); 1";
like($@, qr/"no_such_function" is not exported by the Stats::LikeR module/,
	'asking for a name that is not exported dies');

# h()'s three documented forms work whether or not the name was imported:
# \&quantile in a package without quantile is a stub there, and h() reads its
# name; a package's own defined quantile is not this module's, so h() dies.
sub capture {
	my ($code) = @_;
	my ($out, $err, @ret) = ('');
	{
		local *STDOUT;
		open STDOUT, '>', \$out or die "cannot redirect STDOUT: $!";
		@ret = eval { $code->() };
		$err = $@;
	}
	return ($out, $err, @ret);
}
for my $case (
	[ 'h(\'quantile\')', sub { Stats::LikeR::h('quantile') } ],
	[ 'h(*quantile)',    sub { no warnings 'once'; Stats::LikeR::h(*Exports::Empty::quantile) } ],
	[ 'h(\&quantile)',   sub { Stats::LikeR::h(\&Exports::Empty::quantile) } ],
) {
	my ($desc, $code) = @$case;
	my ($out, $err, @ret) = capture($code);
	is($err, '', "$desc without importing quantile: lives");
	is_deeply(\@ret, ['quantile'], "$desc without importing quantile: returns its name");
	like($out, qr/quantile/, "$desc without importing quantile: prints its section");
}
{
	package Exports::OwnQuantile;
	sub quantile { 'mine' }
}
my (undef, $err) = capture(sub { Stats::LikeR::h(\&Exports::OwnQuantile::quantile) });
like($err, qr/not a Stats::LikeR function/, "h(\\&quantile) on the caller's own quantile dies");

done_testing();
