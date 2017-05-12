#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for author testing');
  }
}

use Test::More;

eval "use Test::Spelling";
if ( $@ ) {
  plan skip_all => 'Test::Spelling required for testing POD';
}
else {
  add_stopwords(qw(
     Helmut
     Wollmersdorfer
     Mojolicious
  ));
  all_pod_files_spelling_ok();
}


