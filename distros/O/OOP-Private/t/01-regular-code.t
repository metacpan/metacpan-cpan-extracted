use strict;
use warnings;
use 5.010;
use lib "t/lib";

use Test::More tests => 4;
use OOP::Private::Test::Parent;

my $inst = new OOP::Private::Test::Parent 2;

my $sum;
eval { $sum = $inst -> calculateSumWithPrivate(2) };
is +($sum == 4) && (!length $@), 1, "Public methods that rely on private ones are OK";

undef $sum;
eval { $sum = $inst -> calculateSumWithProtected(2) };
is +($sum == 4) && (!length $@), 1, "Public methods that rely on protected ones are OK";

undef $sum;
eval { $sum = $inst -> doPrivateStuff(2) };
is !$sum && ($@ =~ /Attempt to call private subroutine OOP::Private::Test::Parent::doPrivateStuff from outer code/), 1,
    "Private method is not accessible from outside";

eval { $sum = $inst -> doProtectedStuff(2) };
is !$sum && ($@ =~ /Attempt to call protected subroutine OOP::Private::Test::Parent::doProtectedStuff from outer code/), 1,
    "Protected method is not accessible from outside";

done_testing;
