use strict;
use warnings;
{
    package RoleOne;
    use MooseX::MethodAttributes::Role;

    sub foo {}
}
{
    package RoleTwo;
    use MooseX::MethodAttributes::Role;

    sub foo {}
}
{
    package RoleThree;
    use MooseX::MethodAttributes::Role;

    sub foo : Action {}
}
{
    package RoleFour;
    use MooseX::MethodAttributes::Role;

    sub foo : ActionRole {}
}
{
    package MyClass;
    use Moose;
    use Test::More tests => 3;
    use Test::Fatal;

    like exception { with qw/RoleOne RoleTwo/; }, qr/method name conflict/,
        'Normal methods conflict detected';

    like exception { with qw/RoleThree RoleFour/; }, qr/method name conflict/,
        'Attributed methods conflict detected';

    like exception { with qw/RoleOne RoleFour/; }, qr/method name conflict/,
        'Attributed and non attributed methods combination - conflict detected';
}
