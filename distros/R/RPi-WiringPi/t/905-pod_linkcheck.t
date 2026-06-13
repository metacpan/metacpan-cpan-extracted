use warnings;
use strict;

use lib 't/';

use RPiTest;
use Test::More;

unless ( $ENV{RPI_RELEASE_TESTING} ) {
    plan( skip_all => "Author test: RPI_RELEASE_TESTING not set" );
}

eval "use Test::Pod::LinkCheck";
if ($@) {
    plan skip_all => 'Test::Pod::LinkCheck required for testing POD links';
} 

rpi_running_test(__FILE__);

Test::Pod::LinkCheck->new->all_pod_ok;
