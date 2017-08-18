package Test4Impl;

use Moose;
with 'Test4';

has dependency1 => ( is=>'ro', does => 'Test3', required => 1 );

sub do_something {}

1;
