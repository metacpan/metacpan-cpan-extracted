use strict;
use warnings;
use Test::More tests => 6;

use_ok('SWISH::Prog');
use_ok('SWISH::Prog::Config');
use_ok('SWISH::Prog::Native::Indexer');

SKIP: {

    # is executable present?
    my $test = SWISH::Prog::Native::Indexer->new;
    if ( !$test->swish_check ) {
        skip "swish-e not installed", 3;
    }

    ok( my $config = SWISH::Prog::Config->new('t/test.conf'),
        "config from t/test.conf" );

    $config->IndexFile("foo/bar");

    ok( my $prog = SWISH::Prog->new( config => $config, ),
        "new prog object" );

    is( $prog->indexer->invindex->path, "foo/bar",
        "ad hoc IndexFile config" );

}
