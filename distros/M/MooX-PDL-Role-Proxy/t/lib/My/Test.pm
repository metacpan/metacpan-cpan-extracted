#! perl

package My::Test;

use Test2::V0;

use constant NAME => $ENV{MOOX_PDL_ROLE_PROXY_BACKCOMPAT_TEST}
  ? 'Piddle'
  : 'NDarray';


note "Testing with NAME = @{[ NAME() ]}";

1;
