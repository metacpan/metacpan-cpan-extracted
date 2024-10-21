#!perl

use strict;
use warnings;
use 5.010;

use Test::More (tests => 1);

use Perl::Critic::UserProfile;
use Perl::Critic::PolicyFactory (-test => 1);

use Perl::Critic::TestUtils qw(bundled_policy_names);
Perl::Critic::TestUtils::block_perlcriticrc();


my $profile = Perl::Critic::UserProfile->new();
my $factory = Perl::Critic::PolicyFactory->new( -profile => $profile );
my @found_policies = sort map { ref } grep { /Bangs/ } $factory->create_all_policies();
my $test_label = 'successfully loaded policies matches MANIFEST';
is_deeply( \@found_policies, [bundled_policy_names()], $test_label );


exit 0;
