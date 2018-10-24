#!/usr/bin/perl

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

use Overload::FileCheck q/:all/;

use File::Temp qw/ tempfile tempdir /;

my $tmp = tempdir( CLEANUP => 1 );

my $not_there = $tmp . '/not-there';

{
    note "unmocked: not existing file";

    is [ stat($not_there) ], [], "stat not there";
    ok !-e _, "!-e _ - unmocked";
}

mock_all_from_stat( \&my_stat );
my $called = 0;
sub my_stat { $called++; return [] }

{
    note "unmocked: not existing file";

    no warnings;    # throw warnings with Perl <= 5.14

    is [ stat($not_there) ], [], "stat not there";
    is $called, 1, "my_stat was called";
    ok !-e _, "!-e _ - unmocked";
}

done_testing;
