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

use Specio::Library::Union;

{
    is(
        exception { ok( t('Union'), 'type named Union is available' ) },
        undef,
        'no exception retrieving Union type'
    );
}

done_testing();
