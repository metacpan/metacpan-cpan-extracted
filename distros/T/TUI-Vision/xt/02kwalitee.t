use strict;
use warnings;

use Test::More;

BEGIN {
  plan skip_all => 'these tests are for release candidate testing'
    unless $ENV{AUTHOR_TESTING};
}

BEGIN {
  eval "use Test::Kwalitee 'kwalitee_ok'";
  plan skip_all => "Test::Kwalitee required for testing" if $@;
}

kwalitee_ok(
  -has_meta_yml
);

done_testing;
