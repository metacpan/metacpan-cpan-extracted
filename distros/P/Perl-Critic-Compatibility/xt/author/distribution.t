#!/usr/bin/env perl

#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic-Compatibility/xt/author/distribution.t $
#     $Date: 2008-05-09 10:51:28 -0500 (Fri, 09 May 2008) $
#   $Author: clonezone $
# $Revision: 2333 $

# Taken from
# http://www.chrisdolan.net/talk/index.php/2005/11/14/private-regression-tests/.

use 5.006;

use strict;
use warnings;

use version; our $VERSION = qv('v1.1');

# No POD coverage due to complaints about builtins when using Fatal.
use Test::Distribution ( distversion => 1, not => 'podcover' );

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
