
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

use Test::More;

BEGIN {
  eval { require Test::Kwalitee; 1 }
    or plan skip_all => "You need Test::Kwalitee installed to run this test. Its only an authortest though, so thats ok";
}
use Test::Kwalitee tests => [qw( -use_strict )];