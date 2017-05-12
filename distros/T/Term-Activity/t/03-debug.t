use Term::Activity;
use Test::Simple tests => 2;
use strict;

my $t = new Term::Activity ({ debug => 1 });
ok(1);

ok(1) if $Term::Activity::debug == 1;
