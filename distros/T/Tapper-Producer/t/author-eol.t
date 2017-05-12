
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Tapper/Producer.pm',
    'lib/Tapper/Producer/DummyProducer.pm',
    'lib/Tapper/Producer/ExternalProgram.pm',
    'lib/Tapper/Producer/Kernel.pm',
    'lib/Tapper/Producer/NewestPackage.pm',
    'lib/Tapper/Producer/SimnowKernel.pm',
    'lib/Tapper/Producer/Temare.pm',
    't/00-load.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/misc_files/bin/temare',
    't/release-pod-coverage.t',
    't/tapper-producer-temare.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
