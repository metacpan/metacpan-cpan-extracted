######################################################################
#
# 2001_podtest.t
#
# Copyright (c) 2019, 2026 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in US-ASCII.
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

eval q{ use Test::Pod 1.48 tests => 1; };
if ($@) {
    print "1..1\n";
    print "ok 1 - SKIP\n";
}
else {
    pod_file_ok('lib/Modern/Open.pm');
}

__END__
