#!perl

BEGIN {
  unless ( $ENV{ RELEASE_TESTING } ) {
    require Test::More;
    Test::More::plan( skip_all => 'these tests are for release candidate testing' );
  }
}

use Test::More;

eval "use Pod::Wordlist";
plan skip_all => "Pod::Wordlist required for testing POD spelling"
  if $@;

eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD spelling"
  if $@;

set_spell_cmd( 'aspell list' );
add_stopwords( <DATA> );
all_pod_files_spelling_ok( 'lib' );
__DATA__
PPI
filename
