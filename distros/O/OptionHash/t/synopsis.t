#!/usr/bin/perl

use strict;
use warnings;
use OptionHash;
use Test::Simple tests => 2;

use OptionHash;

my $cat_def = ohash_define( keys => [qw< tail nose claws teeth>]);

sub cat{
    my %options = @_;
    ohash_check( $cat_def, \%options);
    # ...
}

cat( teeth => 'sharp' );
eval{cat( trunk => 'long')}; # Boom, will fail. Cats dont expect to have a trunk.
ok($@);

package foo;
use OptionHash;
my $DOG_DEF = ohash_define( keys => [ qw< nose > ]);
sub build_a_dog{
    my( %opts ) = @_;
    ohash_check($DOG_DEF, \%opts);
}
1;

package main;

foo::build_a_dog( nose => 'blue' );
eval{ foo::build_a_dog( claws => 'blue' );};
ok($@);
