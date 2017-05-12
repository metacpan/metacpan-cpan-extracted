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
        pass("$eventname attribute detected");
    }
}

package main;

use Test::More tests => 3;

my $child = TestObserved->new();
$child->add_observer( TestObserver->new() );
$child->add_observer( TestObserver->new() );
$child->add_observer( TestObserver->new() );

$child->test_setter(2);