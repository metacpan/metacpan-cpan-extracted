use warnings;
use strict;

use lib 't/lib';
use Test::More 0.88;

use if !eval { require Moose; Moose->VERSION('2.1300') },
    'Test::Needs' => 'MooseX::Role::WithOverloading';

use TestOverload_Consumer;
use Pod::Coverage::Moose;

my $pcm = Pod::Coverage::Moose->new(package => 'TestOverload_Consumer');

is_deeply [$pcm->uncovered], [qw( bar )], 'injected helper methods not detected as uncovered, overloaded methods ignored';

done_testing;
