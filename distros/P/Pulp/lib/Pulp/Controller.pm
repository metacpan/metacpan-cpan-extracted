package Pulp::Controller;

use warnings;
use strict;
use true;

sub import {
    strict->import();
    warnings->import();
    true->import();
    my $caller = caller;
}

1;
__END__
