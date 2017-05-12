use strict;
use warnings;

use Test::More;

BEGIN {
   # Ensure a recent version of Test::Pod
   my $min_tp = 1.22;
   eval("use Test::Pod $min_tp; 1")
      or plan skip_all => "Test::Pod $min_tp required for testing POD";
}

all_pod_files_ok();

1;
