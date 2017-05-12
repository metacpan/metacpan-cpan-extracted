use strict;
use warnings;

{
    package TestObserved;

    use Moose;

    has test_setter => (
        is      => 'rw',
        isa     => 'Int',
        default => 0,
    );

    with 'MooseX::Observer::Role::Observable' => { notify_after => [qw~
        test_setter
        test_method
    ~]};
    
    sub test_method {
        my $self = shift;
    }
}


{
    package TestObserver;

    use Test::More;

    use Moose;

    with 'MooseX::Observer::Role::Observer';

    sub update {
        my ( $self, $observed, $args, $eventname ) = @_;
        is($args->[0], 2, 'Args are passed') if ($eventname eq 'test_setter');
        is_deeply($args, [2, [5], { 1 => 1 }], 'Args are passed deeply') if ($eventname eq 'test_method');
    }
}

package main;

use Test::More tests => 2;

my $observed = TestObserved->new();
$observed->add_observer( TestObserver->new() );
$observed->test_setter(2);
$observed->test_method(2, [5], { 1 => 1 });
