# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SWISH-WebService.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('SWISH::WebService') };

ok( my $search = SWISH::WebService->new(q=>'foo'),  "new object");
ok( $search->search,    "search");
ok( $search->render,    "render search");
