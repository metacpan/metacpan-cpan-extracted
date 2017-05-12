use strict;
use warnings;

use Test::Fatal;
use Test::More 0.96;

use lib 't/lib';
use Specio::Library::Combines;

{
    for my $type (qw( X Y Str Undef )) {
        is(
            exception { ok( t($type), "type named $type is available" ) },
            undef,
            "no exception retrieving $type type - exported by combining library"
        );
    }
}

done_testing();
