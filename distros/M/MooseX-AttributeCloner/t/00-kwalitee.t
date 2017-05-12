use Test::More;
use strict;
use warnings;
use English qw(-no_match_vars);

if (!$ENV{TEST_AUTHOR}) {
  my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
  plan( skip_all => $msg );
}

eval {
  require Test::Kwalitee;
};

if($EVAL_ERROR) {
  plan( skip_all => 'Test::Kwalitee not installed; skipping' );
}

Test::Kwalitee->import(tests => [qw(-no_symlinks -has_meta_yml -use_strict)]);
