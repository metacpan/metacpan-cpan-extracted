#!perl

# This file was generated automatically.

BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        require Test::More;

        Test::More::plan( skip_all => 'these tests are for "smoke bot" testing' );
    }
}

use strict;
use warnings;
use Test::More;
use Test::Pod 1.41;

all_pod_files_ok();
