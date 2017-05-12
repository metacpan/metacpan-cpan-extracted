use strict;
use warnings;

{
    package TestParent;

    use Moose;

    has test_parent => (
        is      => 'rw',
        isa     => 'Int',
        default => 0,
    );
    
    has test_parent_from_child => (
        is      => 'rw',
        isa     => 'Int',
        default => 0,
    );

    with 'MooseX::Observer::Role::Observable' => { notify_after => [qw~
        test_parent
    ~]};
}

{
    package TestChild;

    use Moose;
    
    extends 'TestParent';

    has test_child => (
        is      => 'rw',
        isa     => 'Int',
        default => 0,
    );

    with 'MooseX::Observer::Role::Observable' => { notify_after => [qw~
        test_child
        test_parent_from_child
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

use Test::More tests => 4;

my $child = TestChild->new();
$child->add_observer( TestObserver->new() );

$child->test_child(2);
$child->test_parent(2);

my $parent = TestParent->new();
$parent->add_observer( TestObserver->new() );
$parent->test_parent(2);

# 3 Tests till here
$child->test_parent_from_child(5); 
$child->test_parent_from_child; 