use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MooseX/Attribute/ValidateWithException.pm',
    'lib/MooseX/Attribute/ValidateWithException/AttributeRole.pm',
    'lib/MooseX/Attribute/ValidateWithException/Exception.pm',
    't/00-compile/lib_MooseX_Attribute_ValidateWithException_AttributeRole_pm.t',
    't/00-compile/lib_MooseX_Attribute_ValidateWithException_Exception_pm.t',
    't/00-compile/lib_MooseX_Attribute_ValidateWithException_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
