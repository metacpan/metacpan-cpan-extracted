use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Moose/Meta/Attribute/Custom/Trait/Indexed.pm',
    'lib/MooseX/AttributeIndexes.pm',
    'lib/MooseX/AttributeIndexes/Meta/Attribute/Trait/Indexed.pm',
    'lib/MooseX/AttributeIndexes/Meta/Role.pm',
    'lib/MooseX/AttributeIndexes/Meta/Role/ApplicationToClass.pm',
    'lib/MooseX/AttributeIndexes/Meta/Role/ApplicationToRole.pm',
    'lib/MooseX/AttributeIndexes/Meta/Role/Composite.pm',
    'lib/MooseX/AttributeIndexes/Provider.pm',
    'lib/MooseX/AttributeIndexes/Provider/FromAttributes.pm',
    't/00-compile/lib_MooseX_AttributeIndexes_Meta_Attribute_Trait_Indexed_pm.t',
    't/00-compile/lib_MooseX_AttributeIndexes_Meta_Role_ApplicationToClass_pm.t',
    't/00-compile/lib_MooseX_AttributeIndexes_Meta_Role_ApplicationToRole_pm.t',
    't/00-compile/lib_MooseX_AttributeIndexes_Meta_Role_Composite_pm.t',
    't/00-compile/lib_MooseX_AttributeIndexes_Meta_Role_pm.t',
    't/00-compile/lib_MooseX_AttributeIndexes_Provider_FromAttributes_pm.t',
    't/00-compile/lib_MooseX_AttributeIndexes_Provider_pm.t',
    't/00-compile/lib_MooseX_AttributeIndexes_pm.t',
    't/00-compile/lib_Moose_Meta_Attribute_Custom_Trait_Indexed_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-load.t',
    't/02-basic.t',
    't/03-callback.t',
    't/04-roles.t',
    't/lib/Example.pm',
    't/lib/Example2.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
