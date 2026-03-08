use strict;
use warnings;

sub func {
    my @list = (1, 2, 3);

    my @result = map {
        return 0 unless $_;
        return 1 if $_ < 5;
        $_ + 5;
    } @list;

    return @result;
}

print func();
