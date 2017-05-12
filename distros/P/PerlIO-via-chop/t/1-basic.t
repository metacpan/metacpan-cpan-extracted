#!/usr/bin/perl -w
# $File: //member/autrijus/PerlIO-via-chop/t/1-basic.t $ $Author: autrijus $
# $Revision: #1 $ $Change: 1248 $ $DateTime: 2002/10/07 14:07:23 $

use strict;
use Test::More tests => 2;

use_ok('PerlIO::via::chop');

my $string;
open(FH, '>:via(chop)', \$string) or die $!;
print FH 'Hello';
close FH;
is($string, 'Hell');

1;
