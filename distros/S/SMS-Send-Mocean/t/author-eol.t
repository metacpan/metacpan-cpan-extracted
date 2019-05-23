
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
    'lib/SMS/Send/Mocean.pm',
    't/00-compile.t',
    't/000-report-versions.t',
    't/00_load.t',
    't/01_instantiation.t',
    't/02_required.t',
    't/03_to_mocean_field_name.t',
    't/04_send_sms_success.t',
    't/05_send_sms_errors.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/release-distmeta.t',
    't/release-has-version.t',
    't/release-kwalitee.t',
    't/release-unused-vars.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
