# -*-perl-*-

use strict;
use Test::More;
eval "use Test::Pod 1.00";
if ( $@ ) {
    plan skip_all => "Test::Pod 1.00 required for testing POD" ;
}
my @pod_dirs = qw( blib );
all_pod_files_ok( all_pod_files( @pod_dirs ) );
