#!/usr/bin/env perl

#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Task-Perl-Critic-IncludingOptionalDependencies/t/98_pod_syntax.t $
#     $Date: 2008-12-21 13:50:35 -0600 (Sun, 21 Dec 2008) $
#   $Author: clonezone $
# $Revision: 2921 $

use strict;
use warnings;
use Test::More;

eval 'use Test::Pod 1.00';  ## no critic
plan skip_all => 'Test::Pod 1.00 required for testing POD' if $@;
all_pod_files_ok();

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
