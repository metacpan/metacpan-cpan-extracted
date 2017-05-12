use strict;
use warnings;
use Test::More;
use FindBin;
use Package::JSONable;

use lib "$FindBin::Bin/lib";
use Class;

my $object = Class->new;

is_deeply($object->TO_JSON(
    string => 'Str',
),{
    string => 'hello',
}, 'pass different set of params directly to TO_JSON');

done_testing();
