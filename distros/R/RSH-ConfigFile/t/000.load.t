# -*- perl -*-
# ------------------------------------------------------------------------------
#  Copyright © 2003 by Matt Luker.  All rights reserved.
# 
#  Revision:
# 
#  $Header$
# 
# ------------------------------------------------------------------------------

# 00-load.t - makes sure the modules load via "use".
# 
# @author  Matt Luker
# @version $Revision: 3249 $

# 00-load.t - makes sure the modules load via "use".
# 
# Copyright (C) 2003, Matt Luker
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself. 

# If you have any questions about this software,
# or need to report a bug, please contact me.
# 
# Matt Luker
# Port Angeles, WA
# kostya@redstarhackers.com
# 
# TTGOG


use Test::More tests => 4;

BEGIN { use_ok('RSH::Exception') };
BEGIN { use_ok('RSH::SmartHash') };
BEGIN { use_ok('RSH::LockFile') };
BEGIN { use_ok('RSH::ConfigFile') };

exit 0;

# ------------------------------------------------------------------------------
# 
#  $Log$
#  Revision 1.2  2003/10/15 01:07:00  kostya
#  documentation and license updates--everything is Artistic.
#
#  Revision 1.1.1.1  2003/10/13 01:38:04  kostya
#  First import
#
# 
# ------------------------------------------------------------------------------

