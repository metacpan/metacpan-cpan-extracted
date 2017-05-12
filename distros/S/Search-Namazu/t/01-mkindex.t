# $Id: 01-mkindex.t 267 2006-06-09 05:43:51Z knok $
#

use strict;
use Test;

BEGIN { plan tests => 1 };

system("rm -r t/index t/index/en t/index/ja");
system("mkdir t/index t/index/en t/index/ja");
system("env LANG=C LC_ALL= LC_CTYPE= mknmz -q -O t/index/en t/data/en");
system("env LANG=ja LC_ALL= LC_CTYPE= mknmz -q -O t/index/ja t/data/ja");
ok(1);
