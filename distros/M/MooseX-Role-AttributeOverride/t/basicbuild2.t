use strict;
use warnings;

{

    package MyApp::Role;
    use Moose::Role;
    use MooseX::Role::AttributeOverride;

    has_plus 'fun' => ( builder => '_build_fun' );

    1;

}
{

    package MyApp;
    use Moose;

    has 'fun' => (
        is  => 'rw',
        isa => 'Str'
    );

    with qw(MyApp::Role);

    sub _build_fun {
        return 'yep';
    }

    1;

}
{

    package main;

    #use MyApp;

    use Test::More tests => 1;    # last test to print

    my $test = MyApp->new();

    is( $test->fun, 'yep', "Default was set by role" );

}
