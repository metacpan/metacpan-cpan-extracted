package Test::Class::Simple::NoModuleTest;
use strict;
use warnings;

use parent qw(Test::Class::Simple);

sub create_instance {
    return 0;
}

sub get_module_name {
    return;
}

sub test_check_reference : Test(1) {
    my $self = shift;

    $self->run_on_module(1);
    my $test_cases = [
        {
            method => 'check_reference',
            params => [],
            exp    => undef,
            name   => 'No module specified',
        },
    ];
    $self->run_test_cases($test_cases);
    return;
}

1;
