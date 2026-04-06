use v5.26;
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Test::Pod; 1 }
      or plan skip_all => 'Test::Pod required for author POD checks';
}

Test::Pod::all_pod_files_ok( 'lib', 'bin' );
