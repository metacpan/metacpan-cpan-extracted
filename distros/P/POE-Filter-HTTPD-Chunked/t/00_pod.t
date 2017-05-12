use strict;
use warnings;

use Test::More;

if ( $ENV{ AUTHOR } ) {
    eval "use Test::Pod 1.14";
    plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;

    all_pod_files_ok();
} else {
    plan skip_all => "Not running POD tests unless \$ENV{ AUTHOR } set"
}
