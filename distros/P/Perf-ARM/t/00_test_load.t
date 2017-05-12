#!/opt/perl5/bin/perl -w
#---------------------------------------------------------------------------
#  Copyright (c) 1999 Hewlett-Packard Company. All rights reserved.
#  This program is free software; you can redistribute it
#  and/or modify it under the same terms as Perl itself.
#
#  $Author: bbacker $
#  $Date: 2001/09/19 18:43:23 $
#  $Revision: 1.2 $
#
#---------------------------------------------------------------------------

use strict;
use Perf::ARM;

use Test;
BEGIN {plan test=>1}

my $where;

if ($where=$INC{"Perf/ARM.pm"}) {
    print "got Perf::ARM module from \n",$where,"\n";
    print "Perf::ARM::VERSION=",$Perf::ARM::VERSION,"\n";

} else {
    die "didn't seem to find Perf::ARM.pm in your normal INC path\n";
}

ok(1);
