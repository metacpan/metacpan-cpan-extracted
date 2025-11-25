#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;
use Perl::Critic::TestUtils qw( pcritique );

my $code;

$code = <<'__CODE__';
    foreach my $foo (1..10) {
        print $foo;
    }
}
__CODE__
is pcritique( 'BuiltinFunctions::ProhibitForeach', \$code ), 1, 'Spotted a foreach';
