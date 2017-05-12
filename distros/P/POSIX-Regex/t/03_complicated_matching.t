# vi:fdm=marker fdl=0 syntax=perl:
# $Id: 03_complicated_matching.t,v 1.2 2006/08/18 20:40:53 jettero Exp $

use strict;
use Test;

plan tests => 7;

use POSIX::Regex qw(REG_EXTENDED);

# NOTE: BSD doesn't have \| on "obsolete" basic REs for some reason
# NOTE: wow, only linux has the \| under basic REs.
my $r = new POSIX::Regex('a(a|b)(c)', REG_EXTENDED);

my @m = $r->match("aac");
ok( $m[0], "aac" );
ok( $m[1], "a" );
ok( $m[2], "c" );

@m = $r->match("abc");
ok( $m[0], "abc" );
ok( $m[1], "b" );
ok( $m[2], "c" );

@m = $r->match("lol!!");
ok( int @m => 0 );
