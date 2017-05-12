########################################################################
# File:     00post.t
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: 90post.t,v 1.2 2000/02/08 03:09:42 winters Exp winters $
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

### skip the tests if no NS-SLAPD is running ###
if ($Config{SkipTests} eq 'Y') {
  print "1..0\n";
  exit;
}

print "1..1\n";

### clean up files ###
cleanup_env(\%Config);
print "ok 1\n";
