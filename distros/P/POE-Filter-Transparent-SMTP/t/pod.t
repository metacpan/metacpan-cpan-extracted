#!perl

# Copyright (c) 2008-2009 George Nistorica
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.  See the LICENSE
# file that comes with this distribution for more details.

# 	($rcs) = (' $Id: pod.t,v 1.3 2009/01/28 12:37:41 george Exp $ ' =~ /(\d+(\.\d+)+)/);	

use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval qq{use Test::Pod $min_tp};
plan skip_all => qq{Test::Pod $min_tp required for testing POD} if $@;

all_pod_files_ok();
