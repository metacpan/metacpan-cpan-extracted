use strict;
use warnings;

{
    package TestAttributes;

    use Moose;

    has [qw~ test_rw test_ro ~] => (
        is      => 'rw',
        isa     => 'Int',
        default => 0,
    );

    with 'MooseX::Observer::Role::Observable' => { notify_after => [qw~
        test_ro test_rw
    ~]};
}

{
    package TestObserver;

    use Test::More;

    use Moose;

    with 'MooseX::Observer::Role::Observer';

    sub update {
        my ( $self, $observed, $args, $eventname ) = @_;
        
        if ($eventname eq 'test_rw') {
            pass('changes to writable attribute detected');
        } elsif ($eventname eq 'test_ro') {
            fail('readoperations should not be detected');
        }
    }
}

package main;

use Test::More tests => 1;

my $attr = TestAttributes->new();
$attr->add_observer( TestObserver->new() );

$attr->test_rw(2);
$attr->test_ro;