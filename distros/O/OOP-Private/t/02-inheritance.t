use strict;
use warnings;
use 5.010;
use lib "t/lib";

use Test::More tests => 2;
use OOP::Private::Test::Child;

my $inst = new OOP::Private::Test::Child 2;

my $sum;

eval { $sum = $inst -> accessParentPrivate(2) };
ok !$sum && $@ =~ /Attempt to call private subroutine OOP::Private::Test::Parent::doPrivateStuff from outer code/,
    "Parent's private methods are not available for child classes";

eval { $sum = $inst -> accessParentProtected(2) };
ok +($sum == 4) && (!length $@), "Parent's protected methods are available for child classes";

done_testing;
