use Test::More;
use strict;
use warnings;
use lib 't/lib';

use_ok 'Foo';

my $subject = Foo->new;

ok $subject->foobar;

ok $subject->foobar2('test');

done_testing;
