#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More 0.47;

use Perl::MinimumVersion;
my @examples_not=(
    q'open(my $tmp, "+>", "a") or die;',
    q'open(my $tmp, undef) or die;',
    q'$obj->open(my $tmp, ">", undef);',
	q{open INFO,   "<  datafile"  or print undef, "can't open datafile: ",$!;},
);
my @examples_yes=(
    q'open(my $tmp, "+>", undef) or die;',
    q'open my $tmp, "+>", undef or die;',
    q'open my $tmp, "+>", undef;',
);
plan tests =>(@examples_not+@examples_yes);
my $method='_open_temp';
foreach my $example (@examples_not) {
	my $p = Perl::MinimumVersion->new(\$example);
	is( $p->$method, '', $example )
	  or do { diag "\$\@: $@" if $@ };
}
foreach my $example (@examples_yes) {
	my $p = Perl::MinimumVersion->new(\$example);
	ok( $p->$method, "$example - detected")
	  or do { diag "\$\@: $@" if $@ };
}

