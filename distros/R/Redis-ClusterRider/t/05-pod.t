use 5.008000;
use strict;
use warnings;

use Test::More;
eval "use Test::Pod 1.44";

if ( $@ ) {
  plan skip_all => "Test::Pod 1.44 required for testing POD";
}

all_pod_files_ok();
