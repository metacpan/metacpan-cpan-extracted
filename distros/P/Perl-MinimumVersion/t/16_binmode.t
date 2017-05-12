#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.47;

#use version;
use Perl::MinimumVersion;
my %examples=(
    q{binmode(FH))}	=> undef,
    q{binmode(r($fh,2))}	=> undef,

    q{binmode(1, func())}	=> 5.006,
    q{binmode(1, ':raw')}	=> 5.006,
    q{binmode(1, ' : raw ')}	=> 5.006,
    q{binmode(1, ' : raw '.':utf8')}	=> 5.006,

    q{binmode(1, ':utf8')}	=> 5.008,
    q{binmode($fh->mthod, q/:utf8/)}	=> 5.008,
    
    q{binmode(1, ":$utf8")}	=> 5.006,
);
plan tests => scalar(keys %examples);
foreach my $example (sort keys %examples) {
	my $p = Perl::MinimumVersion->new(\$example);
	my ($v, $obj) = $p->_binmode_2_arg;
	is( $v, $examples{$example}, $example )
	  or do { diag "\$\@: $@" if $@ };
}
