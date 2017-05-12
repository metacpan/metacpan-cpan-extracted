#
# $Id: load.t,v 1.5 2007/04/08 09:13:38 nick Exp $
#
# Copyright (C) 2001 - 2007 Network Ability Ltd.  All rights reserved.  This
# software may be redistributed under the terms of the license included in
# this software distribution.  Please see the file "LICENSE" for further
# details.

print "1..1\n";

use strict;

eval "use Rcs::Agent";

if ($@) {
	print "not ";
}

print "ok 1\n";
