package Pulp::Model;

use warnings;
use strict;
use true;

sub import {
    my ($class, %args) = @_;
    warnings->import();
    strict->import();
    true->import();

    my $caller = caller;
    my $with_api = 0;
    if ($args{'-api'} and $args{'-api'} == 1) {
        $with_api = 1;
    }

    {
        no strict 'refs';
        *{"${caller}::_use_api"} = sub { $with_api };
    }
}

1;
__END__
