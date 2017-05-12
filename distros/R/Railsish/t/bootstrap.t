#!/usr/bin/env perl

use Test::More 'no_plan';
use Railsish::Bootstrap;

can_ok("Railsish::Bootstrap", qw(load_configs load_controllers load_helpers));

diag join("\n- ",@INC);
for (qw(controllers helpers models)) {
    ok(grep(/\Q$_\E/, @INC));
}


