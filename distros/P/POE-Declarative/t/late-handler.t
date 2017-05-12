use strict;
use warnings;

use POE;
use POE::Declarative;

use Test::More tests => 10;

on _start => run {
    yield count => 1;
};

on count => run {
    my $count = get ARG0;

    return if $count > 10;

    on "count_$count" => run {
        pass("count $count");
    };

    yield count => $count + 1;
    yield "count_$count";
};

on _default => run {
    return 0 unless get(ARG0) =~ /^count_\d+$/;
    fail(get ARG0);
    return 0;
};

POE::Declarative->setup;
POE::Kernel->run;
