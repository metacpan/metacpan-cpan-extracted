#! perl
use Test::More;

BEGIN {
  eval { require Test::Distribution };
  plan 'skip_all' => 'Test::Distribution not installed' if $@;
}

$ENV{TEST_VERBOSE}
  or plan 'skip_all' => 'Distribution tests selected only in verbose mode';

Test::Distribution->import;
diag "package: $_" for Test::Distribution::packages();
diag "file: $_" for Test::Distribution::files();
