# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use TestPW;

my $input = weaver_input();

my $weaver = Pod::Weaver->new_with_default_config;

test_basic($weaver, $input);

done_testing;
