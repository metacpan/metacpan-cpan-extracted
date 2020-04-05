#!/usr/bin/perl
#
# This file is part of StorageDisplay
#
# This software is copyright (c) 2020 by Vincent Danjean.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use Test2::V0;

use StorageDisplay;

is( StorageDisplay::Elem->disp_size(5150212096), '4.80 GiB', "Perl round");

done_testing;   # reached the end safely

