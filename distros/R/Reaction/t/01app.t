use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
  local $ENV{DBIC_OVERWRITE_HELPER_METHODS_OK} = 1;
  use_ok 'Catalyst::Test', 'ComponentUI';
}

ok( request('/')->is_success, 'Request should succeed' );
