#!/usr/bin/env perl
#
# This file is part of MooseX-RelatedClasses
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

use strict;
use warnings;

use Test::More 0.88;

eval "use Test::NoSmartComments";
plan skip_all => 'Test::NoSmartComments required for checking comment IQ'
    if $@;

no_smart_comments_in("lib/MooseX/RelatedClasses.pm");
no_smart_comments_in("t/00-compile.t");
no_smart_comments_in("t/00-report-prereqs.dd");
no_smart_comments_in("t/00-report-prereqs.t");
no_smart_comments_in("t/all_in_namespace.t");
no_smart_comments_in("t/basic.t");
no_smart_comments_in("t/blank_namespace.t");
no_smart_comments_in("t/custom-decamelization.t");
no_smart_comments_in("t/desnaking-with-doublecolon.t");
no_smart_comments_in("t/funcs.pm");
no_smart_comments_in("t/lib/Test/Class/__WONKY__.pm");
no_smart_comments_in("t/lib/Test/Class/__WONKY__/One.pm");
no_smart_comments_in("t/lib/Test/Class/__WONKY__/Sub/One.pm");
no_smart_comments_in("t/multiple.t");
no_smart_comments_in("t/sugar.t");

done_testing();
