package Test1Impl;

use Moose;
with 'Test1';

with 'MooseX::DIC::Injectable' => {
	implements => 'Test1'
};

sub do_something {}

1;
