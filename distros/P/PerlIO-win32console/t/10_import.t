#!perl
use strict;
use warnings;
use Test::More;

use PerlIO::win32console;

ok( eval <<'EOS', "auto push to output");
use PerlIO::win32console "-installout";
1;
EOS

ok( !eval <<'EOS', "unknown import");
use PerlIO::win32console "-unknown";
1;
EOS

done_testing();