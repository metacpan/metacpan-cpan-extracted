#!/usr/bin/env perl

#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Task-Perl-Critic-IncludingOptionalDependencies/t/99_pod_coverage.t $
#     $Date: 2008-12-21 13:50:35 -0600 (Sun, 21 Dec 2008) $
#   $Author: clonezone $
# $Revision: 2921 $

use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage 1.00 requried to test POD' if $@;

all_pod_coverage_ok();

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
