use strict;
use warnings;
use Test::More;

use Sub::Data::Recursive;

{
    my $hash = +{
        bar => 1,
    };

    Sub::Data::Recursive->invoke(
        sub { $_[0]++ },
        $hash,
    );

    my $expect = +{
        bar => 2,
    };

    is_deeply $hash, $expect, 'simple';
}

{
    my $hash = [1, 2, 3];

    Sub::Data::Recursive->invoke(
        sub { $_[0]++ },
        $hash,
    );

    my $expect = [2, 3, 4];

    is_deeply $hash, $expect, 'simple2';
}

{
    my $hash = +{
        bar => +{
            baz => 2
        },
        qux => 1,
    };

    Sub::Data::Recursive->invoke(
        sub { $_[0]++ },
        $hash,
    );

    my $expect = +{
        bar => +{
            baz => 3
        },
        qux => 2,
    };

    is_deeply $hash, $expect, 'scalar';
}

{
    my $hash = +{
        bar => +{
            baz => [2, 3]
        },
        qux => [1, 2],
    };

    Sub::Data::Recursive->invoke(
        sub { $_[0]++ },
        $hash,
    );

    my $expect = +{
        bar => +{
            baz => [3, 4]
        },
        qux => [2, 3],
    };

    is_deeply $hash, $expect, 'array';
}

{
    my $hash = +{
        bar => +{
            baz => +{ hoge => 2 },
        },
        qux => +{ page => 1 },
    };

    Sub::Data::Recursive->invoke(
        sub { $_[0]++ },
        $hash,
    );

    my $expect = +{
        bar => +{
            baz => +{ hoge => 3 },
        },
        qux => +{ page => 2 },
    };

    is_deeply $hash, $expect, 'hash';
}

done_testing;
