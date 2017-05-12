# vi:fdm=marker fdl=0 syntax=perl:
# $Id: 01_load.t,v 1.3 2006/08/18 19:50:18 jettero Exp $

use strict;
use Test;

plan tests => 1;

eval {use POSIX::Regex; }; ok( not $@ );
