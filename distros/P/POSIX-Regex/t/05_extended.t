# vi:fdm=marker fdl=0 syntax=perl:
# $Id: 05_extended.t,v 1.1 2006/08/19 12:06:54 jettero Exp $

use strict;
use Test;

plan tests => 4;

use POSIX::Regex qw(:all);

my $r1 = new POSIX::Regex('ab(c)', REG_ICASE);
my $r2 = new POSIX::Regex('ab(c)', REG_EXTENDED, REG_ICASE);

ok( $r1->match("abC"), 0 );
ok( $r2->match("abC"), 1 );


$r1 = new POSIX::Regex('lol.*man', REG_EXTENDED);
$r2 = new POSIX::Regex('lol.*man', REG_EXTENDED, REG_NEWLINE);

my $string = q(
lol
man
);

ok( $r1->match($string), 1 );
ok( $r2->match($string), 0 );
