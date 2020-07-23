use strictures 2;

use Test::InDistDir;
use Test::More;
use Test::Fatal;

BEGIN {
    package RoleA;
    use Moo::Role;
    use MooX::ShortHas;
    ro 'attr1';

    package RoleB;
    use Moo::Role;
    use MooX::ShortHas;
    ro 'attr2';

    package Thing;
    use Moo;
}

run();
done_testing;
exit;

sub run {
    my $class;
    ok ! exception {
        $class = Moo::Role->create_class_with_roles('Thing', qw(RoleA RoleB));
    }, 'can apply roles';
    my $thing = $class->new( attr1 => 'a', attr2 => 'b' );
    ok $thing->can('attr1'), 'has attr1';
    ok $thing->can('attr2'), 'has attr2';

    return;
}
