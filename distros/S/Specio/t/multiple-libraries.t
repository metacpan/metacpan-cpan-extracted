use strict;
use warnings;

use FindBin qw( $Bin );

my $lib_path;

BEGIN {
    if ( $Bin =~ /xt/ ) {
        $lib_path = "$Bin/../../t";
    }
    else {
        $lib_path = "$Bin";
    }
}

use lib "$lib_path/lib";

use Test::Fatal;
use Test::More 0.96;

use Specio::Library::Builtins;
use Specio::Library::XY;

{
    for my $type (qw( X Y Str Undef )) {
        is(
            exception { ok( t($type), "type named $type is available" ) },
            undef,
            "no exception retrieving $type type"
        );
    }
}

done_testing();
