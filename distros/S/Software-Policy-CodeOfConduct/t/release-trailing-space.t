#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}


use strict;
use warnings;

use Test::More;

eval "use Test::TrailingSpace";
if ($@)
{
   plan skip_all => "Test::TrailingSpace required for trailing space test.";
}
else
{
   plan tests => 1;
}

# TODO: add .pod, .PL, the README/Changes/TODO/etc. documents and possibly
# some other stuff.
my $finder = Test::TrailingSpace->new(
   {
       root => '.',
       filename_regex => qr#\.(?:p[lm]|pod)\z#,
   },
);

# TEST
$finder->no_trailing_space(
   "No trailing space was found."
);
