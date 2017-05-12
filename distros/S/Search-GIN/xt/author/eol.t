use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Search/GIN.pm',
    'lib/Search/GIN/Callbacks.pm',
    'lib/Search/GIN/Core.pm',
    'lib/Search/GIN/DelegateToIndexed.pm',
    'lib/Search/GIN/Driver.pm',
    'lib/Search/GIN/Driver/Hash.pm',
    'lib/Search/GIN/Driver/Pack.pm',
    'lib/Search/GIN/Driver/Pack/Delim.pm',
    'lib/Search/GIN/Driver/Pack/IDs.pm',
    'lib/Search/GIN/Driver/Pack/Length.pm',
    'lib/Search/GIN/Driver/Pack/UUID.pm',
    'lib/Search/GIN/Driver/Pack/Values.pm',
    'lib/Search/GIN/Driver/TXN.pm',
    'lib/Search/GIN/Extract.pm',
    'lib/Search/GIN/Extract/Attributes.pm',
    'lib/Search/GIN/Extract/Callback.pm',
    'lib/Search/GIN/Extract/Class.pm',
    'lib/Search/GIN/Extract/Delegate.pm',
    'lib/Search/GIN/Extract/Multiplex.pm',
    'lib/Search/GIN/Indexable.pm',
    'lib/Search/GIN/Keys.pm',
    'lib/Search/GIN/Keys/Deep.pm',
    'lib/Search/GIN/Keys/Expand.pm',
    'lib/Search/GIN/Keys/Join.pm',
    'lib/Search/GIN/Query.pm',
    'lib/Search/GIN/Query/Attributes.pm',
    'lib/Search/GIN/Query/Class.pm',
    'lib/Search/GIN/Query/Manual.pm',
    'lib/Search/GIN/Query/Set.pm',
    'lib/Search/GIN/SelfIDs.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/attrs.t',
    't/class.t',
    't/core.t',
    't/key_expansion.t',
    't/rels.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
