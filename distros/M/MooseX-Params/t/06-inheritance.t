use strict;
use warnings;

use Test::Most;

{
    package TestParent;

    use Moose;
    use MooseX::Params;

    sub test
        :Args(self: Int first)
        :BuildArgs(_buildargs_test)
    { $_{first} }

    sub _buildargs_test { shift, 42 }

    __PACKAGE__->meta->make_immutable;
}

{
    package TestInherit;

    use Moose;
    extends 'TestParent';

    __PACKAGE__->meta->make_immutable;
}

{
    package TestOverride;

    use Moose;
    extends 'TestParent';

    sub test { return $_[1] }

    __PACKAGE__->meta->make_immutable;
}

{
    package TestInheritClassic;

    use base 'TestParent';
}

my $parent = TestParent->new;
my $inheriting = TestInherit->new;
my $overriding = TestOverride->new;
my $inheriting_classic = TestInheritClassic->new;

is($parent->test(24), 42, 'parent method');
is($inheriting->test(24), 42, 'inherited method with extends');
is($inheriting_classic->test(24), 42, 'inherited method with base');
is($overriding->test(24), 24, 'overriden method');

done_testing;

