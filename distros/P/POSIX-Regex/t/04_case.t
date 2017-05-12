# vi:fdm=marker fdl=0 syntax=perl:
# $Id: 04_case.t,v 1.1 2006/08/18 20:40:53 jettero Exp $

use strict;
use Test;

plan tests => 4;

use POSIX::Regex qw(:all);

my $r1 = new POSIX::Regex('abc');
my $r2 = new POSIX::Regex('abc', REG_ICASE);

ok( $r1->match("abc"), 1 );
ok( $r1->match("aBc"), 0 );

ok( $r2->match("abc"), 1 );
ok( $r2->match("aBc"), 1 );
