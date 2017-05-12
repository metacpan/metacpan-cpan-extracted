################################################################################
#
#  Copyright 2011 Zuse Institute Berlin
#
#  This package and its accompanying libraries is free software; you can
#  redistribute it and/or modify it under the terms of the GPL version 2.0,
#  or the Artistic License 2.0. Refer to LICENSE for the full license text.
#
#  Please send comments to kallies@zib.de
#
################################################################################
#
# Test if Hwloc module can be loaded
#
# $Id: 00-use.t,v 1.7 2011/01/11 10:49:39 bzbkalli Exp $
#
################################################################################

use Test::More tests => 5;

BEGIN { use_ok('Sys::Hwloc', 0.05) };
use strict;

require_ok('Sys::Hwloc') or
  BAIL_OUT("Hwloc module cannot be loaded");

can_ok('Sys::Hwloc', 'HWLOC_API_VERSION') or
  BAIL_OUT("constant HWLOC_API_VERSION not there");

can_ok('Sys::Hwloc', 'HWLOC_XSAPI_VERSION') or
  BAIL_OUT("constant HWLOC_XSAPI_VERSION not there");

can_ok('Sys::Hwloc', 'HWLOC_HAS_XML') or
  BAIL_OUT("constant HWLOC_HAS_XML not there");

