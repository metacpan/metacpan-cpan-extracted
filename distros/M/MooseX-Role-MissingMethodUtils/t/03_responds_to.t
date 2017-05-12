use Test::More;
use strict;
use warnings;
use lib 't/lib';

use_ok 'Foo';

my $subject = Foo->new;

ok $subject->responds_to('foobar3');

my $ref = $subject->responds_to('foobar3');

is &{$ref}(), 'foobar_3';

done_testing;
