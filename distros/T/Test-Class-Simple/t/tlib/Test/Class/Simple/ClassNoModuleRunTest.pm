package Test::Class::Simple::ClassNoModuleRunTest;
use strict;
use warnings;

use parent qw(Test::Class::Simple);

sub post_setup {
    my $self = shift;

    my $instance = $self->get_instance();
    $instance->{_counter} = 100;
    return;
}

sub get_module_name {
    return 'Test::Class::Simple::Class';
}

sub create_instance {
    return 1;
}

sub test_increase_counter : Test(1) {
    my $self = shift;

    my $test_cases = [
        {
            method => 'increase_counter',
            params => [],
            exp    => 101,
            name   => 'Increase counter once',
        },
    ];
    $self->run_test_cases($test_cases);
    return;
}
1;
