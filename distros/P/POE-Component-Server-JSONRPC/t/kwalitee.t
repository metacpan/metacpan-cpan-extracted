use Test::More;
use strict;
use warnings;
eval "use Test::Kwalitee 'kwalitee_ok'";
BEGIN {
  plan skip_all => "Test::Kwalitee required for testing Kwalitee" if $@;
  plan skip_all => 'these tests are for release candidate testing'
    unless $ENV{RELEASE_TESTING};
}
kwalitee_ok();
done_testing;
