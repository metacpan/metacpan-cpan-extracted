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

my $ver = 1.22; # Ensure a recent version of Test::Pod
eval "use Test::Pod $ver";
plan skip_all => "Test::Pod $ver required for testing POD" if $@;
all_pod_files_ok();

1;

__END__
