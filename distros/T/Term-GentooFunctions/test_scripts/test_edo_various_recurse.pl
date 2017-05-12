
die "you're not running this right, use make test" unless -d "blib/lib";
BEGIN { unshift @INC, "blib/lib" }

use strict;
use warnings;
use Term::GentooFunctions qw(:all);

edo "test1" => sub {
    einfo "point 1";
    edo "test2" => sub {
        einfo "point 2";
        einfo "point 2";
    };
    einfo "point 1";
};
