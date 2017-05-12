use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Pod/Weaver/PluginBundle/Author/KENTNL.pm',
    'lib/Pod/Weaver/PluginBundle/Author/KENTNL/Collectors.pm',
    'lib/Pod/Weaver/PluginBundle/Author/KENTNL/Core.pm',
    'lib/Pod/Weaver/PluginBundle/Author/KENTNL/Postlude.pm',
    'lib/Pod/Weaver/PluginBundle/Author/KENTNL/Prelude.pm',
    'lib/Pod/Weaver/PluginBundle/Author/KENTNL/Role/Easy.pm',
    't/00-compile/lib_Pod_Weaver_PluginBundle_Author_KENTNL_Collectors_pm.t',
    't/00-compile/lib_Pod_Weaver_PluginBundle_Author_KENTNL_Core_pm.t',
    't/00-compile/lib_Pod_Weaver_PluginBundle_Author_KENTNL_Postlude_pm.t',
    't/00-compile/lib_Pod_Weaver_PluginBundle_Author_KENTNL_Prelude_pm.t',
    't/00-compile/lib_Pod_Weaver_PluginBundle_Author_KENTNL_Role_Easy_pm.t',
    't/00-compile/lib_Pod_Weaver_PluginBundle_Author_KENTNL_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/core_inflate.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
