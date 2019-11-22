package Promise::ES6::Mojo;

use strict;
use warnings;

use parent qw( Promise::ES6::EventLoopBase );

sub _postpone {
    (undef, my $cb) = @_;

    Mojo::IOLoop->next_tick($cb);
}

1;
