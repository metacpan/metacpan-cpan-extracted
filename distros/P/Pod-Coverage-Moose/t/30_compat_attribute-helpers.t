use warnings;
use strict;

use Test::More 0.88;
use lib 't/lib/';

use Test::Needs 'MooseX::AttributeHelpers';

use TestAttributeHelpers_Consumer;
use Pod::Coverage::Moose;

my $pcm = Pod::Coverage::Moose->new(package => 'TestAttributeHelpers_Consumer');

is_deeply [$pcm->uncovered], [qw( bar )], 'injected helper methods not detected as uncovered';

done_testing;
