use 5.010;
use strict;
use warnings;
use Test::More;

use Test::Changes::Strict::Simple -empty_line_after_version => 1;

plan skip_all => 'Release and "additional" tests only'
  unless $ENV{RELEASE_TESTING} && $ENV{RELEASE_TEST_ADDN};
plan tests => 1;

changes_strict_ok(module_version => $Test::Changes::Strict::Simple::VERSION,
                  release_today  => 1
                 );
