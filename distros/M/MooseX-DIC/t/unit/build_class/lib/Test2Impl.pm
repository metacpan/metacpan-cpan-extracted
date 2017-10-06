package Test2Impl;

use Moose;
with 'Test2';

with 'MooseX::DIC::Injectable' => { implements => 'Test2' };

sub method1 {}

1;
