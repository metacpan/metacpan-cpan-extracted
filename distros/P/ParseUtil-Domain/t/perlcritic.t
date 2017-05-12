use strict;
use warnings;
use Modern::Perl;
use Test::More;
use English qw(-no_match_vars);
use File::Spec;

if (not $ENV{TEST_AUTHOR}) {
    my $msg = 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan skip_all => $msg;
}

eval {require Test::Perl::Critic};

if ($EVAL_ERROR) {
    my $msg = 'Test::Perl::Critic required to criticise code.';
    plan skip_all => $msg;
}

my $rc_file = File::Spec->catfile('t','perlcriticrc');
Test::Perl::Critic->import(-profile => $rc_file);
my $num_of_tests;
++$num_of_tests and critic_ok('lib/ParseUtil/Domain.pm') ;

done_testing($num_of_tests);
