use warnings;
use strict;

use Test::More tests => 5;

BEGIN { use_ok "Module::Runtime", qw(module_notional_filename); }

is module_notional_filename("Test::More"), "Test/More.pm";
is module_notional_filename("Test::More::Widgets"), "Test/More/Widgets.pm";
is module_notional_filename("Foo::0Bar::Baz"), "Foo/0Bar/Baz.pm";
is module_notional_filename("Foo"), "Foo.pm";

1;
