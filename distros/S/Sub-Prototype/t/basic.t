use strict;
use warnings;
use Test::More tests => 4;
use Sub::Prototype;

BEGIN {
    my $my_grep = sub {
        my $code = shift;
        my @ok;
        $code->() and push @ok, $_ for @_;
        return @ok;
    };
    set_prototype($my_grep, '&@');
    is(prototype($my_grep), '&@');
    *main::my_grep = $my_grep;
}

is(prototype('my_grep'), '&@');
is(prototype(\&my_grep), '&@');
is_deeply([ my_grep { $_ % 2 } 1 .. 10 ], [1, 3, 5, 7, 9]);
