use strict;
use warnings;

use Test::More;
use lib 't/lib';

use MooseX::Types::LoadableClass qw/ LoadableClass /;

my $c = to_LoadableClass("ClobberDollarUnderscore");
ok $c;

done_testing;


