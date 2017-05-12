#!/usr/local/bin/perl
use strict;

use SysAdmin;

my $results = SysAdmin::_check_socket("localhost","5432");

print "Results $results\n";
