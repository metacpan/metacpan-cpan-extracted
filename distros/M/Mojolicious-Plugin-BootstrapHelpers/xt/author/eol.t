use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Mojolicious/Plugin/BootstrapHelpers.pm',
    'lib/Mojolicious/Plugin/BootstrapHelpers/Helpers.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/badge-1.t',
    't/bootstrap-1.t',
    't/button-1.t',
    't/button_group-1.t',
    't/context_menu-1.t',
    't/dropdown-1.t',
    't/formgroup-1.t',
    't/icon-1.t',
    't/input_group-1.t',
    't/nav-1.t',
    't/navbar-1.t',
    't/panel-1.t',
    't/table-1.t',
    't/toolbar-1.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
