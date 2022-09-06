use strictures 2;

use Test::InDistDir;
use Test::More;
use Test::Fatal;

BEGIN {
    package RoleA;
    use Moose::Role;
    use MooseX::ShortHas;
    ro 'attr1';

    package RoleB;
    use Moose::Role;
    use MooseX::ShortHas;
    ro 'attr2';

    package Thing;
    use Moose;
    with "RoleA", "RoleB";
}

run();
done_testing;
exit;

sub run {
    my $thing = Thing->new( attr1 => 'a', attr2 => 'b' );
    ok $thing->can('attr1'), 'has attr1';
    ok $thing->can('attr2'), 'has attr2';

    return;
}
