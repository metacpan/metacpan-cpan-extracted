use warnings;
use strict;

use lib 't/lib';
use Test::More;

use if !eval { require Moose; Moose->VERSION('2.1300') },
    'Test::Requires' => 'MooseX::Role::WithOverloading';

use_ok  'TestOverload_Consumer',    'consumer test class loaded ok';
use_ok  'Pod::Coverage::Moose',             'pcm loaded ok';

my $pcm = Pod::Coverage::Moose->new(package => 'TestOverload_Consumer');

is_deeply [$pcm->uncovered], [qw( bar )], 'injected helper methods not detected as uncovered, overloaded methods ignored';

done_testing;
