package Test::Class::Simple::ClassTest;
use strict;
use warnings;

use parent qw(Test::Class::Simple);

sub _setup {
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

sub test_increase_counter : Test(5) {
    my $self = shift;

    my $instance   = $self->get_instance();
    my $test_cases = [
        {
            method => 'increase_counter',
            params => [],
            exp    => 101,
            name   => 'Increase counter once',
        },
        {
            method         => 'increase_counter',
            params         => [],
            exp            => 102,
            name           => 'Increase counter twice',
            post_test_hook => sub { $instance->{_counter} = 0; },
        },
        {
            method => 'increase_counter',
            params => [],
            exp    => 1,
            name   => 'Increase counter after reset',
        },
        {
            method        => 'increase_counter',
            pre_test_hook => sub { $instance->{_counter} = 100; },
            params        => [],
            exp           => 101,
            name          => 'Increase counter after setup',
        },
        {
            method => 'increase_counter',
            params => [],
            exp    => sub {
                my $result = shift;

                return ( $result == 102 ) ? 1 : 0;
            },
            name => 'Increase counter after setup',
        },
    ];
    $self->run_test_cases($test_cases);
    return;
}
1;
