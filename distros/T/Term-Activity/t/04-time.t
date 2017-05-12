use Term::Activity;
use Test::Simple tests => 2;
use strict;

my $t = new Term::Activity ({ time => 100 });
ok(1);

ok(1) if $Term::Activity::start == 100;
