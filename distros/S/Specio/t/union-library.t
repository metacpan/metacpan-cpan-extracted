use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/lib";

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
