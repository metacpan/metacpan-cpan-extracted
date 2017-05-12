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
    ~]};
    
}


{
    package TestObserver;

    use Test::More;

    use Moose;

    with 'MooseX::Observer::Role::Observer';

    sub update {
        my ( $self, $observed, $args, $eventname ) = @_;
        pass("$eventname observed");
    }
}

package main;

use Test::More tests => 10;

my $observed = TestObserved->new();
my $test_observer1 = TestObserver->new();
my $test_observer2 = TestObserver->new();

$observed->add_observer($_) for ($test_observer1, $test_observer2);
is($observed->count_observers, 2, '2 observers found');
$observed->test_setter(2); # should call pass twice

$observed->remove_observer($test_observer1);
is($observed->count_observers, 1, '1 observers found');
$observed->test_setter(2); # should call pass only once

$observed->remove_observer($test_observer2);
is($observed->count_observers, 0, '0 observers found');
$observed->test_setter(2); # should not call pass

# 6 test should be run until here

$observed->add_observer($test_observer1);
$observed->add_observer($test_observer1);
$observed->add_observer($test_observer1);

is($observed->count_observers, 3, 'correct observercount after adding');
$observed->remove_observer($test_observer1);
is($observed->count_observers, 0, 'correct observercount after removing instance');


$observed->add_observer($test_observer1);
$observed->add_observer($test_observer1);
$observed->add_observer($test_observer2);

is($observed->count_observers, 3, 'correct observercount after adding again');
$observed->remove_all_observers();
is($observed->count_observers, 0, 'correct observercount after clearing');
