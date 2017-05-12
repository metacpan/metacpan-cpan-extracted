
die "you're not running this right, use make test" unless -d "blib/lib";
BEGIN { unshift @INC, "blib/lib" }

use strict;
use warnings;
use Term::GentooFunctions qw(:all);

equiet(1) if $ENV{SHH_QUIET};

edo "making file" => sub {
    open OUT, ">file" or die "CREATE ERROR: $!"; close OUT;

    edo "rming file" => sub { unlink "file" or die "UNLINK ERROR: $!" };
};

edo "rming file again (fail)" => sub { unlink "file" or die "UNLINK ERROR: $!" };
