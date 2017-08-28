package Test2Impl;

use Moose;
with 'Test2';

with 'MooseX::DIC::Injectable' => { implements => 'Test2', scope => 'request' };

sub do_something {}

1;
