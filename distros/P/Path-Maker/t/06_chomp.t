use strict;
use warnings FATAL => "all";
use Test::More;
use t::Util;

use Path::Maker;

my $LF = "\x0a";

my $maker = Path::Maker->new;
is $maker->render('test1'), "test1 line$LF";
is $maker->render('test2'), "test2 line$LF$LF";
is $maker->render('test3'), "test3 line$LF";

done_testing;

__DATA__

@@ test1
test1 line

@@ test2
test2 line


@@ test3
test3 line
