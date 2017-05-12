use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Params/Validate.pm',
    'lib/Params/Validate/Constants.pm',
    'lib/Params/Validate/PP.pm',
    'lib/Params/Validate/XS.pm',
    'lib/Params/ValidatePP.pm',
    'lib/Params/ValidateXS.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-validate.t',
    't/02-noop.t',
    't/04-defaults.t',
    't/05-noop_default.t',
    't/06-options.t',
    't/07-with.t',
    't/08-noop_with.t',
    't/09-regex.t',
    't/10-noop_regex.t',
    't/11-cb.t',
    't/12-noop_cb.t',
    't/13-taint.t',
    't/14-no_validate.t',
    't/15-case.t',
    't/16-normalize.t',
    't/17-callbacks.t',
    't/18-depends.t',
    't/19-untaint.t',
    't/21-can.t',
    't/22-overload-can-bug.t',
    't/23-readonly.t',
    't/24-tied.t',
    't/25-undef-regex.t',
    't/26-isa.t',
    't/27-string-as-type.t',
    't/28-readonly-return.t',
    't/29-taint-mode.t',
    't/30-hashref-alteration.t',
    't/31-incorrect-spelling.t',
    't/32-regex-as-value.t',
    't/33-keep-errsv.t',
    't/34-recursive-validation.t',
    't/35-default-xs-bug.t',
    't/36-large-arrays.t',
    't/37-exports.t',
    't/38-callback-message.t',
    't/39-reentrant.t',
    't/lib/PVTests.pm',
    't/lib/PVTests/Callbacks.pm',
    't/lib/PVTests/Defaults.pm',
    't/lib/PVTests/Regex.pm',
    't/lib/PVTests/Standard.pm',
    't/lib/PVTests/With.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
