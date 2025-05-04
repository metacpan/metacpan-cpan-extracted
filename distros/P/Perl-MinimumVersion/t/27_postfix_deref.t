#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.47;

#use version;
use Perl::MinimumVersion;

my @examples=(
    [ q{$a->$*;}		=> '5.020' ],
    [ q{$a->@*;}		=> '5.020' ],
    [ q{$a->%*;}		=> '5.020' ],
    [ q{$a->&*;}		=> '5.020' ],
    [ q{$a->**;}		=> '5.020' ],
    [ q{$a->$#*;}		=> '5.020' ],
    [ q{$a->@[1..3];}		=> '5.020' ],
    [ q{$a->@{ qw{ foo bar } }}	=> '5.020' ],
    [ q{$a->%[1..3];}		=> '5.020' ],
    [ q{$a->%{ qw{ foo bar } }}	=> '5.020' ],
);

plan tests => scalar @examples;
foreach my $info ( @examples ) {
	my ( $example, $version ) = @{ $info };
	my $p = Perl::MinimumVersion->new(\$example);
	my $v = $p->minimum_version;
	is( $v, $version, $example )
	  or do { diag "\$\@: $@" if $@ };
}
