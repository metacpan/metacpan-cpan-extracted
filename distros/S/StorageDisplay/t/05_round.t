#!/usr/bin/perl
#
# This file is part of StorageDisplay
#
# This software is copyright (c) 2014-2023 by Vincent Danjean.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use Test2::V0;

use StorageDisplay::Data::Elem;

is( StorageDisplay::Data::Elem->disp_size(5150212096), '4.80 GiB', "Perl round");
is( StorageDisplay::Data::Elem->disp_size(4387131392), '4.09 GiB', "Perl round");
is( StorageDisplay::Data::Elem->disp_size(4386631092), '4.09 GiB', "Perl round");
is( StorageDisplay::Data::Elem->disp_size(4386131092), '4.08 GiB', "Perl round");
is( StorageDisplay::Data::Elem->disp_size(43871313920), '40.9 GiB', "Perl round");
is( StorageDisplay::Data::Elem->disp_size(43866310920), '40.9 GiB', "Perl round");
is( StorageDisplay::Data::Elem->disp_size(43861310920), '40.8 GiB', "Perl round");

done_testing;   # reached the end safely

