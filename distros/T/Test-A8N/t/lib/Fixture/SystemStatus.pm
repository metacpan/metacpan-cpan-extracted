package Fixture::SystemStatus;

use strict;
use warnings;
use Moose;
BEGIN {
    extends 'Fixture';
}
use Test::More;

sub systemstatus : Test {
    my ($self, $file) = @_;
    pass('System Status test works');
}

1;

