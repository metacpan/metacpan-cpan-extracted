use strict;
use warnings;

use Test::More 0.88;
use lib 't/lib';

use MooseX::Types::LoadableClass qw/ LoadableClass /;

my $c = to_LoadableClass("ClobberDollarUnderscore");
ok $c;

done_testing;


