#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use Test::More;

eval "use Pod::Wordlist";
plan skip_all => "Pod::Wordlist required for testing POD spelling"
  if $@;

eval "use Test::Spelling 0.12";
plan skip_all => "Test::Spelling 0.12 required for testing POD spelling"
  if $@;

set_spell_cmd('aspell list');
add_stopwords(<DATA>);
all_pod_files_spelling_ok('lib');
__DATA__
CPAN
github
stopwords
wordlist
Rodrigo
de
Oliveira
