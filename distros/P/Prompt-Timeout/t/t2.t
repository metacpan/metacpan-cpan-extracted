#!/usr/bin/env perl -w

# $Id: t2.t 1 2009-08-31 14:00:42Z stro $

use strict;
use Test;

BEGIN { plan tests => 1 }

use Prompt::Timeout;

my $res = prompt('Press <Enter> or wait 1 second', 'DEF', 1);

ok($res, 'DEF');

exit;
