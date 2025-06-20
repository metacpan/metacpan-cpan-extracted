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

use Specio::Library::WithSubs;

ok( t('Int'),                   'Int type is available' );
ok( t('PositiveInt'),           'PositiveInt type is available' );
ok( __PACKAGE__->can('is_Int'), 'is_Int() was exported from library' );
ok(
    __PACKAGE__->can('is_PositiveInt'),
    'is_PositiveInt() was exported from library'
);

done_testing();
