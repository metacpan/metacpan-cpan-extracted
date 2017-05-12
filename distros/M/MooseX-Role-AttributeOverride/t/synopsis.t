use strict;
use warnings;

{

    package MyApp::Role;
    use Moose::Role;
    use MooseX::Role::AttributeOverride;

    has_plus 'fun' => ( default => 'yep', );

    has_plus 'alive' => (
        default                 => 'yep',
        override_ignore_missing => 1,
    );
}
{

    package MyApp::Trait;
    use Moose::Role;
    use MooseX::Role::AttributeOverride;

    has_plus default => (
        default => sub {
            my $attr = shift;
            return sub { $attr->name }
        }
    );
}
{

    package MyApp;
    use Moose 1.9900;

    has nolife => (
        is     => 'rw',
        isa    => 'Str',
        traits => ['MyApp::Trait'],
    );

    has 'fun' => (
        is  => 'rw',
        isa => 'Str'
    );

    with qw(MyApp::Role);
}
{

    package main;
    use Test::More tests => 2;

    my $test = MyApp->new();

    is( $test->nolife, 'nolife', 'Trait usage works.' );
    is( $test->fun,    'yep',    'Setting attr default works.' );
}
