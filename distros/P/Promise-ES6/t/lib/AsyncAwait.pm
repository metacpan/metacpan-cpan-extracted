package AsyncAwait;

use strict;
use warnings;

use Test::More;

sub for_each_event_interface {
    my ($todo_cr) = @_;

    my @usable_backends;

    if (eval "require AnyEvent") {
        push @usable_backends, ['AnyEvent'];
    }

    if (eval "require IO::Async::Loop") {
        push @usable_backends, ['IO::Async', IO::Async::Loop->new()];
    }

    if (eval 'require Mojo::IOLoop') {
        push @usable_backends, ['Mojo::IOLoop'];
    }

    if (@usable_backends) {
        for my $backend_ar (@usable_backends) {
            note "Testing: $backend_ar->[0]";

            Promise::ES6::use_event(@$backend_ar);

            $todo_cr->();
        }
    }

    return 0 + @usable_backends;
}

1;
