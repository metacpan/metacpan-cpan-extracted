#!/usr/bin/env perl
#
# This file is part of MooseX-Types-Tied
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

use Test::More tests => 1;

BEGIN { use_ok 'MooseX::Types::Tied' }

diag("Testing MooseX-Types-Tied $MooseX::Types::Tied::VERSION, Perl $], $^X");
