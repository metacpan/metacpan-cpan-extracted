use strict;
use warnings FATAL => 'all';
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use Pod::Elemental::Transformer::Splint;

Pod::Elemental::Transformer::Splint->new;

is 1, 1, 'Loaded';

done_testing;
