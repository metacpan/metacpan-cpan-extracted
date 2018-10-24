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

use Overload::FileCheck '-e' => \&my_dash_e, ':check';

my @exist     = qw{cherry banana apple};
my @not_there = qw{mum and dad};

sub my_dash_e {
    my $f = shift;

    note "mocked -e called for", $f;

    return CHECK_IS_TRUE  if grep { $_ eq $f } @exist;
    return CHECK_IS_FALSE if grep { $_ eq $f } @not_there;

    # we have no idea about these files
    return FALLBACK_TO_REAL_OP;
}

foreach my $f (@exist) {
    ok( -e $f, "file '$f' exists" );
}

foreach my $f (@not_there) {
    ok( !-e $f, "file '$f' exists" );
}

ok -e $0,  q[$0 is there];
ok -e $^X, q[$^X is there];

done_testing;
