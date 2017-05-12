use strict;
use warnings;

{

    package MyApp::RoleA;
    use Moose::Role;
    use MooseX::Role::AttributeOverride;

    has_plus 'fun' => ( default => 'yep', );

    no Moose::Role;

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

    no Moose::Role;

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

    __PACKAGE__->meta->make_immutable;
    no Moose;

}
{

    package main;

    use Test::More tests => 2;

    my $test = MyApp->new();

    is( $test->fun, 2, "Default was set by role and updated" );
    $test->have;
    is( $test->fun, 3, "can be modified" );

}
