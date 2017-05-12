use strict;
use warnings;

{

    package MyApp::RoleA;
    use Moose::Role;
    use MooseX::Role::AttributeOverride;

    has_plus 'fun' => ( default => 'yep', );

    1;

}
{

    package MyApp::RoleB;
    use Moose::Role;
    use MooseX::Role::AttributeOverride;

    requires qw(have);

    has_plus 'fun' => (
        default => '2',
        isa     => 'Int',
    );

    1;

}
{

    package MyApp;
    use Moose;

    has 'fun' => (
        is  => 'rw',
        isa => 'Str'
    );

    sub have {
        shift->fun(3);
    }

    with qw(MyApp::RoleA MyApp::RoleB);

    1;

}
{

    package main;

    use Test::More tests => 2;

    my $test = MyApp->new();

    is( $test->fun, 2, "Default was set by role and updated" );
    $test->have;
    is( $test->fun, 3, "can be modified" );

}
