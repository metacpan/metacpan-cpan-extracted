########################################################################
# File:     00post.t
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: 90post.t,v 1.1 2000/02/10 01:52:38 winters Exp winters $
#
# This script cleans up the test environment.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

require 't/common.pl';

my %Config;  ### holds config info for tests ###
load_config(\%Config);

print "1..1\n";

### clean up files ###
cleanup_env(\%Config);
print "ok 1\n";
