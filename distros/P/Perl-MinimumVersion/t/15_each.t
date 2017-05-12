#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.47;

#use version;
use Perl::MinimumVersion;
my %examples=(
    q/$HASH{each}/      => undef,
    q{$obj->each(@foo)} => undef,
    q{each %foo}        => undef,
    q'each % { $foo }'  => undef,
    q'each %{ $foo }'   => undef,
    q{each @foo}        => 5.012,
    q{each $ref}        => 5.014,
    q{each @foo; each $ref}        => 5.014,
    q{each $foo; each @ref}        => 5.014,
    q{each $ref->call}  => 5.014,
    q{each call()}      => 5.014,
    q{each(%foo)}       => undef,
    q{each(@foo)}       => 5.012,
    q'each(@{$foo})'    => 5.012,
    q'each @{$foo} '    => 5.012,
    q'each @ {$foo} '   => 5.012,
    q{each($ref)}       => 5.014,
    q{each($ref->call)} => 5.014,
    q{each(call())}     => 5.014,

    q{keys %foo}        => undef,
    q'sub keys;'        => undef,
    q'sub keys {}'      => undef, # RT#82718
    q{$obj->keys(@foo)} => undef,
    q{keys @foo}        => 5.012,
    q{keys $ref}        => 5.014,
    q{keys $ref->call}  => 5.014,
    q{keys call()}      => 5.014,
    q{keys(%foo)}       => undef,
    q{keys(@foo)}       => 5.012,
    q{keys($ref)}       => 5.014,
    q{keys($ref->call)} => 5.014,
    q{keys(call())}     => 5.014,

    q{values %foo}        => undef,
    q{values @foo}        => 5.012,
    q{values $ref}        => 5.014,
    q{values $ref->call}  => 5.014,
    q{values call()}      => 5.014,
    q{values(%foo)}       => undef,
    q{values(@foo)}       => 5.012,
    q{values($ref)}       => 5.014,
    q{values($ref->call)} => 5.014,
    q{values(call())}     => 5.014,
);
plan tests => scalar(keys %examples);
foreach my $example (sort keys %examples) {
	my $p = Perl::MinimumVersion->new(\$example);
	my ($v, $obj) = $p->_each_argument;
	is( $v, $examples{$example}, $example )
	  or do { diag "\$\@: $@" if $@ };
}
