# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

# $Id: 00-load.t,v 1.3 2002/11/15 23:55:43 lem Exp $

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 4 };
use Net::FTPServer::PWP::Server;
ok(1); # If we made it this far, we're ok.
use Net::FTPServer::PWP::Handle;
ok(2); # If we made it this far, we're ok.
use Net::FTPServer::PWP::DirHandle;
ok(3); # If we made it this far, we're ok.
use Net::FTPServer::PWP::FileHandle;
ok(4); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

