########################################################################
# File:     00pre.t
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: 00pre.t,v 1.2 2000/02/08 03:09:42 winters Exp winters $
#
# This script prepares the test environment.
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Persistent::File;
use Persistent::LDAP;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

require 't/common.pl';

my %Config;  ### holds config info for tests ###
load_config(\%Config);
prepare_env(\%Config);

### eval all of the persistent code to catch any exceptions ###
eval {

  ### Test #2: Allocate an object ###
  my $person = undef;
  $person = new_person(\%Config);
  test(2, defined $person, "new failed ($person == undef)");
};

if ($@) {
  warn "An exception occurred: $@\n";
}
