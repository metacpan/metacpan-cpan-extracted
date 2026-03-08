use strict;
use warnings;

sub func {
    my @list = (3, 1, 2);

    my @result = sort {
        return $a <=> $b unless $a;
        $a <=> $b;
    } @list;

    return @result;
}

print func();
