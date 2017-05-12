# Emacs, this is -*-perl-*- code.

BEGIN { use Test; plan tests => 1; }

use strict;

use Test;

eval "use Pragmatic;";
ok (not $@);
