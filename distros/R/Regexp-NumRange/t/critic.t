#!perl

use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

unless ( $ENV{RELEASE_TESTING} ) {
    my $msg = 'Author test.  Set $ENV{RELEASE_TESTING} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Perl::Critic; };

if ($EVAL_ERROR) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan( skip_all => $msg );
}

Test::Perl::Critic->import(
    -severity => 3,
    -verbose  => 10,
    -exclude  => ['ProhibitExcessComplexity', 'RequireExtendedFormatting']
);
all_critic_ok();
