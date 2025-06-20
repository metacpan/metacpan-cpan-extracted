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

use Specio::Library::XY;

require Specio::Library::Conflict;

like(
    exception { Specio::Library::Conflict->import },
    qr/\QThe main package already has a type named X/,
    'Got an exception when a library import conflicts with already declared types'
);

done_testing();
