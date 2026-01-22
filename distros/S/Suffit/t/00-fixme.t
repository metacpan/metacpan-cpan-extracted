#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2026 D&D Corporation
#
# This program is distributed under the terms of the Artistic License 2.0
#
#########################################################################
use strict;
use Test::More;

eval "use Test::Fixme";
plan skip_all => "requires Test::Fixme to run" if $@;
run_tests(
    where => [qw/lib/],
    match => qr/\s+([T]ODO|[F]IX(ME|IT)?|[B]UG)\W/,
    warn => 1,
);

1;

__END__
