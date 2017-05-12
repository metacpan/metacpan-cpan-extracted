########################################################################
# File:     00pre.t
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: 00pre.t,v 1.1 2000/02/10 00:18:58 winters Exp winters $
#
# This script prepares the test environment.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Persistent::DBI;
$loaded = 1;

######################### End of black magic.

require 't/common.pl';

my %Config;  ### holds config info for tests ###
load_config(\%Config);
prepare_env(\%Config);
print "ok 1\n";
