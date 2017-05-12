# vi:fdm=marker fdl=0 syntax=perl:
# $Id: 02_simple_matching.t,v 1.1 2006/08/18 19:50:18 jettero Exp $

use strict;
use Test;

plan tests => 8;

use POSIX::Regex qw(REG_EXTENDED);

my $r1 = new POSIX::Regex('cd');

ok($r1->re_nsub, 0);

ok( scalar $r1->match("abcd"), 1 );
ok( scalar $r1->match("dcba"), 0 );

# NOTE: BSD doesn't have \| on "obsolete" basic REs for some reason
# NOTE: wow, only linux has the \| under basic REs.
my $r2 = new POSIX::Regex('a(a|b)c', REG_EXTENDED);

ok($r2->re_nsub, 1);

ok( scalar $r2->match("aac"), 1 );
ok( scalar $r2->match("abc"), 1 );
ok( scalar $r2->match("azc"), 0 );

my $r3 = new POSIX::Regex('a(b(c(d)))(e)', REG_EXTENDED);

ok($r3->re_nsub, 4);

