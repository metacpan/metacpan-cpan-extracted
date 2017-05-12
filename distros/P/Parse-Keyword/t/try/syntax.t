use strict;
use warnings;
use Test::More;
use lib 't/try/lib';

BEGIN {
    if (!eval { require Try::Tiny }) {
        plan skip_all => "This test requires Try::Tiny";
    }
}

use Try;

my $err;

try {
    require Error1;
}
catch {
    $err = $_;
}
like(
    $err,
    qr/Can't call method "finallyy" without a package or object reference at |Can't locate object method "finallyy" via package "1" \(perhaps you forgot to load "1"\?\) at /,
);

try {
    require Error2;
}
catch {
    $err = $_;
}
like(
    $err,
    qr/Can't call method "catch" without a package or object reference at |Can't locate object method "catch" via package "1" \(perhaps you forgot to load "1"\?\) at /,
);

done_testing;
