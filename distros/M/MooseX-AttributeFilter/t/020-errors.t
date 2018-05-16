#
use strict;
use warnings;
use Test2::V0;

plan 2;

eval {
    package BadRef;
    use Moose;
    use MooseX::AttributeFilter;

    has attr => (
        is     => 'rw',
        filter => {},
    );
    1;
};
like(
    $@,
    qr/type constraint/,
    "filter's incorrect ref"
);

eval {
    package BadMethod;
    use Moose;
    use MooseX::AttributeFilter;

    has attr => (
        is     => 'rw',
        filter => 'noFilter',
    );
    1;
};
like(
    $@,
    qr/No filter method 'noFilter' defined for BadMethod attribute 'attr'/,
    "no filter method"
);

done_testing;
