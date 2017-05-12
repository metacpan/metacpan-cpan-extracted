use strict;
use warnings;

use Config;
BEGIN {
    if ($] < 5.008009) {
        print("1..0 # Skip Needs Perl 5.8.9 or later\n");
        exit(0);
    }
    if (! $Config{useithreads}) {
        print("1..0 # Skip Threads not supported\n");
        exit(0);
    }
}

use threads;
use threads::shared;

BEGIN {
    if ($threads::shared::VERSION lt '1.15') {
        print("1..0 # Skip Needs threads::shared 1.15 or later\n");
        exit(0);
    }
}

use Test::More 'tests' => 4;

package Foo; {
    use Object::InsideOut qw/:NOT_SHARED/;
}

package Bar; {
    use Object::InsideOut qw/:SHARED/;
}

package main;

sub thr_func {
    eval {
        my $obj = Foo->new();
    };
    ok(! $@);

    eval {
        my $obj = Bar->new();
    };
    ok(! $@);
}

MAIN:
{
    eval {
        my $obj = Foo->new();
    };
    ok(! $@);

    eval {
        my $obj = Bar->new();
    };
    ok(! $@);

    threads->create(\&thr_func)->join();
}

exit(0);

# EOF
