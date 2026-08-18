#!perl
use v5.26;
use warnings;
use Test::More;

do_tests();
done_testing();

#######################################################################

sub do_tests {
  require_ok('PlackX::Framework');
}
