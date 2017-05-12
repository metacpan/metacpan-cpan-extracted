use strict;
use warnings;
no warnings qw/ uninitialized /;

use Test::More;

$ENV{ TEST_AUTHOR } =~ /Pod::Manual/ and eval q{
    use Test::Perl::Critic;
    goto RUN_TESTS;
};

plan skip_all => $@
       ? 'Test::Perl::Critic not installed; skipping perlcritic testing'
       :   q{Set TEST_AUTHOR to 'Pod::Manual' in your environment }
         . q{ to enable these tests};

RUN_TESTS: 

Test::Perl::Critic::all_critic_ok();
