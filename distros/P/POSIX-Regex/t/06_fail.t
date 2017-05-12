# vi:fdm=marker fdl=0 syntax=perl:
# $Id$

use strict;
use warnings;
use Test;

plan tests => 2;

use POSIX::Regex qw(REG_EXTENDED);

my $r;

eval { $r = new POSIX::Regex('cd(', REG_EXTENDED); };
my $err = $@;
	
ok(!$r);

ok($err, qr/(?:balanced|unbalanced|unmatched|error)/i);
