use warnings;
use strict;

use Test::More;
use lib 't/lib/';

use Test::Requires 'MooseX::AttributeHelpers';

use_ok  'TestAttributeHelpers_Consumer',    'consumer test class loaded ok';
use_ok  'Pod::Coverage::Moose',             'pcm loaded ok';

my $pcm = Pod::Coverage::Moose->new(package => 'TestAttributeHelpers_Consumer');

is_deeply [$pcm->uncovered], [qw( bar )], 'injected helper methods not detected as uncovered';

done_testing;
