package Test::Class::Simple::ModuleTest;
use strict;
use warnings;

use parent qw(Test::Class::Simple);
use Test::Class::Simple::Module;

sub create_instance {
    return 0;
}

sub get_module_name {
    return 'Test::Class::Simple::Module';
}

sub test_check_reference : Test(3) {
    my $self = shift;

    $self->run_on_module(1);
    my $test_cases = [
        {
            method => 'check_reference',
            params => [],
            exp    => 0,
            name   => 'No data passed to function',
        },
        {
            method => 'check_reference',
            params => ['test'],
            exp    => 0,
            name   => 'Not reference passed to function',
        },
        {
            method => 'check_reference',
            params => [ {} ],
            exp    => 1,
            name   => 'Reference passed to function',
        }
    ];
    $self->run_test_cases($test_cases);
    return;
}

1;
