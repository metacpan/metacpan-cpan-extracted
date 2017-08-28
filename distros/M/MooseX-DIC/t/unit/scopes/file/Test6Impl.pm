package Test6Impl;

use Moose;
with 'Test6';

has dependency1 => ( is=>'ro', does => 'Test5', required => 1 );

sub do_something {}

1;
