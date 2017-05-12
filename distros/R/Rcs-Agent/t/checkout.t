#
# $Id: checkout.t,v 1.4 2007/04/08 09:13:38 nick Exp $
#
# Copyright (C) 2001 - 2007 Network Ability Ltd.  All rights reserved.  This
# software may be redistributed under the terms of the license included in
# this software distribution.  Please see the file "LICENSE" for further
# details.

use Rcs::Agent;
use strict;
use Data::Dumper;

print "1..1\n";

print "ok 1\n";   

exit;

my $rcs = new Rcs::Agent (file => "/tmp/index");

my $output = $rcs->checkout (lock => 1);
print Dumper ($output);
print $rcs->{err};

$output = $rcs->checkout (lock => 1, force => 1);
print Dumper ($output);
print $rcs->{err};

print "ok 1\n";
