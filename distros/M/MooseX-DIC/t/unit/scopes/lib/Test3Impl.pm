package Test3Impl;

use Moose;
with 'Test3';

with 'MooseX::DIC::Injectable' => { implements => 'Test3' };

has dependency1 => ( is => 'ro', does => 'Test2', scope => 'request', traits => [ 'Injected' ]);

sub do_something {}

1;
