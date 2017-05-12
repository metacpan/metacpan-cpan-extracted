use strict;
use Test::More tests => 2;

use Plack::Builder::Conditionals -prefix => 's';

ok( s_path('/')->({ PATH_INFO => '/' }) );

eval {
    path('/')->({ PATH_INFO => '/' });
};
ok( $@ );
