package Test4Impl;

use Moose;
with 'Test4';

with 'MooseX::DIC::Injectable' => {	implements => 'Test4', scope => 'singleton' };

has dependency1 => ( is => 'ro', does => 'Test1', scope => 'request', traits => [ 'Injected' ]);

sub do_something {}

1;
