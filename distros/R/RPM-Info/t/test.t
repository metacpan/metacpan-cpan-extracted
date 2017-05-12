#!/usr/bin/perl -w
use strict;
use Test;
BEGIN { plan tests => 3 }

use RPM::Info; ok(1); 

my $rpm = new RPM::Info(); ok(2); 

my $ver = $rpm->getRpmVer(); ok(3);


exit;
__END__
