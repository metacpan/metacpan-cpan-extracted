#!perl
#
# This file is part of MooseX-RelatedClasses
#
# This software is Copyright (c) 2017, 2015, 2014, 2013, 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

use Test::More;

eval "use Test::HasVersion";
plan skip_all => "Test::HasVersion required for testing version numbers"
  if $@;
all_pm_version_ok();
