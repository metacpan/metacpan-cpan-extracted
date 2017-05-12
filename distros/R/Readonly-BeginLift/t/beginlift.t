use strict;
use warnings;
use Test::More tests => 3;

use Readonly::BeginLift;
use constant MY_VALUE          => 'foo';
Readonly my $MY_VALUE          => 'bar';
Readonly::Scalar my $MY_VALUE2 => 'baz';

BEGIN {
    is MY_VALUE, 'foo', 'Constants have values at BEGIN time';
    is $MY_VALUE,  'bar', '... and so should Readonly constants';
    is $MY_VALUE2, 'baz', '... and so should Readonly::Scalar constants';
}
