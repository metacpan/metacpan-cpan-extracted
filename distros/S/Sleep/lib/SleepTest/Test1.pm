package SleepTest::Test1;
use strict;
use warnings;

use base 'Sleep::Resource';

use Sleep::Response;

sub get {
    my $self = shift;
    my $request = shift;
    return Sleep::Response->new({data => [ 1, 2, 3 ]});
}

1;

