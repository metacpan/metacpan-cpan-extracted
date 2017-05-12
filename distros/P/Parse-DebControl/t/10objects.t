#!/usr/bin/perl -w

use Test::More tests => 6;

BEGIN {
        chdir 't' if -d 't';
        use lib '../blib/lib', 'lib/', '..';
}

my $mod = "Parse::DebControl";


use_ok("IO::Scalar");
use_ok($mod);

can_ok($mod, "new");
can_ok($mod, "parse_file");
can_ok($mod, "parse_mem");
can_ok($mod, "DEBUG");

