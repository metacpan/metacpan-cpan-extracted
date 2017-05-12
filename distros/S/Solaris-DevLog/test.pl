# $Id: test.pl,v 1.1 2002/02/11 21:51:48 bossert Exp $
# Project:  Solaris::DevLog
# File:     test.pl
# Author:   Greg Bossert <bossert@fuaim.com>, <greg@netzwert.ag>
#
# Copyright (c) 2002 Greg Bossert
#
# This Perl module and its is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use Solaris::DevLog;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

# create a new devlog "handle"
eval {
  $devlog = new Solaris::DevLog();
};

if ($@) {
  warn $@;
  ok(0);
}
else {
  ok(1);
} 

exit;

########################################################################
# end of file test.pl
########################################################################
