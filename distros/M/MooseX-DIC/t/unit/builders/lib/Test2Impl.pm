package Test2Impl;

use Moose;
with 'Test2';

has dependency => ( is => 'ro', does => 'Test1', required => 1, traits => [ 'Injected' ] );

sub do_something { }

1;
