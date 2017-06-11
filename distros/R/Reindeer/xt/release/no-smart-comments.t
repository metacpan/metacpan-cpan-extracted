#!/usr/bin/env perl
#
# This file is part of Reindeer
#
# This software is Copyright (c) 2017, 2015, 2014, 2012, 2011 by Chris Weyl.
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

no_smart_comments_in("lib/Reindeer.pm");
no_smart_comments_in("lib/Reindeer/Builder.pm");
no_smart_comments_in("lib/Reindeer/Role.pm");
no_smart_comments_in("lib/Reindeer/Types.pm");
no_smart_comments_in("lib/Reindeer/Util.pm");
no_smart_comments_in("t/00-compile.t");
no_smart_comments_in("t/00-report-prereqs.t");
no_smart_comments_in("t/basic_load.t");
no_smart_comments_in("t/builder/basic.t");
no_smart_comments_in("t/feature.t");
no_smart_comments_in("t/imports.t");
no_smart_comments_in("t/moosex-abstract/basic.t");
no_smart_comments_in("t/moosex-currieddelegation/basic.t");
no_smart_comments_in("t/moosex-markasmethods/basic.t");
no_smart_comments_in("t/moosex-newdefaults/basic.t");
no_smart_comments_in("t/moosex-strictconstructor/basic.t");
no_smart_comments_in("t/moosex-traitor/basic.t");
no_smart_comments_in("t/optional-traits/autodestruct.t");
no_smart_comments_in("t/optional-traits/env.t");
no_smart_comments_in("t/optional-traits/undeftolerant.t");
no_smart_comments_in("t/types.t");

done_testing();
