
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Music/ToRoman.pm',
    't/00-compile.t',
    't/00-methods.t',
    't/01-methods.t',
    't/02-methods.t',
    't/03-methods.t',
    't/04-methods.t',
    't/05-methods.t',
    't/06-methods.t',
    't/07-methods.t',
    't/08-methods.t',
    't/09-methods.t',
    't/10-methods.t',
    't/11-methods.t',
    't/12-methods.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
