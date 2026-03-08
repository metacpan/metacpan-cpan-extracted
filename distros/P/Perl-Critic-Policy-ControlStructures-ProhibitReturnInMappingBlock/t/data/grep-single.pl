use strict;
use warnings;

sub func {
    my @list = (1, 2, 3);

    my @result = grep {
        return 0 unless $_;
        $_ > 1;
    } @list;

    return @result;
}

print func();
