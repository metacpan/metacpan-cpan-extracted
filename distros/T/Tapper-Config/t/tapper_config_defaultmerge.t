#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN{
        $ENV{TAPPER_CONFIG_FILE} = 't/additional_files/tapper.cfg';
        $ENV{TAPPER_DEVELOPMENT} = 1;
}

use Tapper::Config;
is(Tapper::Config->subconfig->{paths}{output_dir}, '/merge/test/succeeded/',         "config merged");


done_testing();
