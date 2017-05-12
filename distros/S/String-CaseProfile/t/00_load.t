use Test::More tests => 2;

BEGIN { use_ok('String::CaseProfile', qw(get_profile set_profile) ) };

can_ok( __PACKAGE__, qw(get_profile set_profile) );

