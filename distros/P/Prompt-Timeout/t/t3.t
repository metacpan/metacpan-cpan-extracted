#!/usr/bin/env perl -w

# $Id: t3.t 24 2010-11-01 14:47:00Z stro $

use strict;
use Test;

BEGIN { plan tests => 4 }

use Prompt::Timeout;

$|=1;

print STDERR "# This test case's running time is 2 minutes. Use Ctrl-Break to break, Ctrl-C may not work. Don't press any keys during testing run.\n";

ok(prompt('Press <Enter> or wait 1 second. Do not press any other key!', 'DEF', 1, 1), 'DEF');
ok(prompt('Press <Enter> or wait 1 second. Do not press any other key!', 'DEF', 1), 'DEF');
ok(prompt('Press <Enter> or wait 60 seconds. ', 'DEF'), 'DEF'); # 60 seconds to run!
print STDERR "# One minute left.\n";
ok(prompt('Press <Enter> or wait 60 seconds. '), '');           # 60 seconds to run!

exit;
