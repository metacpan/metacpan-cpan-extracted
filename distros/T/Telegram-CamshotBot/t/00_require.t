#!/usr/bin/env perl

use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

require_ok('Telegram::CamshotBot::Util');
require_ok('Telegram::CamshotBot');
done_testing();
