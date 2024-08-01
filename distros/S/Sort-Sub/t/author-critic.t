#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.006

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Sort/Sub.pm','lib/Sort/Sub/asciibetically.pm','lib/Sort/Sub/by_ascii_then_num.pm','lib/Sort/Sub/by_count.pm','lib/Sort/Sub/by_first_num_in_text.pm','lib/Sort/Sub/by_last_num_in_text.pm','lib/Sort/Sub/by_length.pm','lib/Sort/Sub/by_num_in_text.pm','lib/Sort/Sub/by_num_then_ascii.pm','lib/Sort/Sub/by_perl_code.pm','lib/Sort/Sub/by_perl_function.pm','lib/Sort/Sub/by_perl_op.pm','lib/Sort/Sub/by_rand.pm','lib/Sort/Sub/naturally.pm','lib/Sort/Sub/numerically.pm','lib/Sort/Sub/numerically_no_warning.pm','lib/Sort/Sub/randomly.pm','lib/Sort/Sub/record_by_order.pm','lib/Sort/Sub/record_by_reverse_order.pm','lib/Sub/Sort.pm','lib/Test/Sort/Sub.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
