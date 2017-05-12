#!/usr/bin/env perl

#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic-Deprecated/xt/author/pod_syntax.t $
#     $Date: 2010-06-22 15:16:01 -0700 (Tue, 22 Jun 2010) $
#   $Author: clonezone $
# $Revision: 3849 $

use 5.006;

use strict;
use warnings;

our $VERSION = '1.108';

use Test::More;
use Test::Pod;

all_pod_files_ok();

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
