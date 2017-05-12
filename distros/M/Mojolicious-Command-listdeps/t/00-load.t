##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##----------------------------------------------------------------------------
use Test::More;
use Mojo::Base -strict;

use_ok( qq{Mojolicious::Command::listdeps});

ok(Mojolicious::Command::listdeps->new->run() == 0, qq{Can run});


done_testing;
