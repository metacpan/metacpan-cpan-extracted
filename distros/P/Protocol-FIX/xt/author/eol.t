use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Protocol/FIX.pm',
    'lib/Protocol/FIX/BaseComposite.pm',
    'lib/Protocol/FIX/Component.pm',
    'lib/Protocol/FIX/Field.pm',
    'lib/Protocol/FIX/Group.pm',
    'lib/Protocol/FIX/Message.pm',
    'lib/Protocol/FIX/MessageInstance.pm',
    'lib/Protocol/FIX/Parser.pm',
    'lib/Protocol/FIX/TagsAccessor.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/05-constuction.t',
    't/06-extension.t',
    't/10-fields.t',
    't/15-groups.t',
    't/16-components.t',
    't/17-messages.t',
    't/18-tags-accessor.t',
    't/19-message-instance.t',
    't/20-serialize.t',
    't/21-parse.t',
    't/50-synopsis.t',
    't/data/extension-sample.xml',
    't/rc/.perlcriticrc',
    't/rc/.perltidyrc'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
