#!perl
#
# This file is part of MooX-Options
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use t::Test;
use warnings FATAL => 'all';

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => 'these tests are for release candidate testing' );
}

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::Requires { 'Test::Pod' => 1.46 };

all_pod_files_ok();

done_testing();
