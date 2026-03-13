use 5.010;
use strict;
use warnings;
use Test::More tests => 1;

use Test::Changes::Strict::Simple -empty_line_after_version => 1;

plan skip_all => 'Release and "self" tests only'
  unless $ENV{RELEASE_TESTING} && $ENV{RELEASE_SELF_TEST};

changes_strict_ok();
