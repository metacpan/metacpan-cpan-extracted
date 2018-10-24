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

my @calls;

sub mystat {
    my ( $stat_or_lstat, $f ) = @_;

    push @calls, $stat_or_lstat;

    return stat_as_file( size => 1234 );
}

mock_all_from_stat( \&mystat );

if ( $] >= 5.016 ) {
    is -s "/abc", 1234, '-s';
}
else {
    todo "-s '/abc does not return the size..." => sub {
        is -s "/abc", 1234, '-s';
    };
}

is \@calls, ['stat'], "we can only see one stat call";

done_testing;
