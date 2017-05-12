#!/usr/bin/env perl
#
# This file is part of PerlIO-via-GnuPG
#
# This software is Copyright (c) 2013 by Chris Weyl.
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

no_smart_comments_in("lib/PerlIO/via/GnuPG.pm");
no_smart_comments_in("lib/PerlIO/via/GnuPG/Maybe.pm");
no_smart_comments_in("t/00-compile.t");
no_smart_comments_in("t/00-report-prereqs.dd");
no_smart_comments_in("t/00-report-prereqs.t");
no_smart_comments_in("t/basic.t");
no_smart_comments_in("t/gpghome/pubring.gpg");
no_smart_comments_in("t/gpghome/secring.gpg");
no_smart_comments_in("t/gpghome/trustdb.gpg");
no_smart_comments_in("t/input.txt");
no_smart_comments_in("t/input.txt.asc");

done_testing();
