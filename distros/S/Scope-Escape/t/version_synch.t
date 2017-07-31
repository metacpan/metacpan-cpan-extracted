use warnings;
use strict;

use Test::More tests => 3;

BEGIN { require_ok "Scope::Escape"; }
my $main_ver = $Scope::Escape::VERSION;
ok defined($main_ver), "have main version number";
is $Scope::Escape::Continuation::VERSION, $main_ver, "version number matches";

1;
