#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.47;

use Perl::MinimumVersion;
my %examples=(
    q{qr/a/} => '5.005',
    q{m/a\z/} => '5.005',
    q{s#\Ra##} => '5.009005',
    q{s/\Ra//u} => '5.013010',
    q{m/a/} => undef,
    q{/(\?|I)/} => undef,
    q{m xfoox} => undef, #unsupported by PPIx::Regexp
    #q{/(\?>I)/} => undef,
    #q{/(\?:I)/} => undef,
    
);
plan tests => scalar(keys %examples);
foreach my $example (sort keys %examples) {
	my $p = Perl::MinimumVersion->new(\$example);
	my ($v, $obj) = $p->_regex;
	is( $v, $examples{$example}, $example )
	  or do { diag "\$\@: $@" if $@ };
}
