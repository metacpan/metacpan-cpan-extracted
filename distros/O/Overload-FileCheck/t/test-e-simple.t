#!/usr/bin/perl -w

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck q(:all);

is [ -e $0 ], [ 1 ], "unmocked -e true";
is [ -e "$0.missing" ], [ undef ], "unmocked -e false";

# we are now mocking the function
ok mock_file_check( 'e', \&my_dash_check ), "mocking -e";

my $dash_e_mocked;

sub my_dash_check {
    my $f = shift;

    note "mocked -e ", $f, " with ", $dash_e_mocked;

    return $dash_e_mocked;
}

$dash_e_mocked = FALLBACK_TO_REAL_OP;
is [ -e $0 ], [ 1 ], "-e FALLBACK_TO_REAL_OP with existing file";
is [ -e "$0.missing" ], [ undef ], "-e FALLBACK_TO_REAL_OP with non existing file";

$dash_e_mocked = CHECK_IS_TRUE;
is [ -e "/this/is/there" ], [ 1 ], "-e CHECK_IS_TRUE";

$dash_e_mocked = CHECK_IS_FALSE;
is [ -e "/this/is/not/there" ], [ undef ], "-e CHECK_IS_FALSE";

done_testing;
exit;

