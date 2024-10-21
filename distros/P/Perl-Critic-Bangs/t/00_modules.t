#!perl

use strict;
use warnings;
use 5.010;

use PPI::Document;
use Test::More;
use Perl::Critic::TestUtils qw(bundled_policy_names);
use English qw(-no_match_vars);

our $VERSION = '1.14';

Perl::Critic::TestUtils::block_perlcriticrc();

my @bundled_policy_names = bundled_policy_names();

plan tests => scalar @bundled_policy_names;

diag( "Testing Perl::Critic::Bangs $VERSION, Perl $], $^X" );

# pre-compute for version comparisons
my $version_string = __PACKAGE__->VERSION;

#-----------------------------------------------------------------------------
# Test module interface for each Policy subclass

for my $mod ( @bundled_policy_names ) {
    subtest $mod => sub {
        plan tests => 14;

        use_ok($mod);
        can_ok($mod, 'applies_to');
        can_ok($mod, 'default_severity');
        can_ok($mod, 'default_themes');
        can_ok($mod, 'get_severity');
        can_ok($mod, 'get_themes');
        can_ok($mod, 'new');
        can_ok($mod, 'set_severity');
        can_ok($mod, 'set_themes');
        can_ok($mod, 'set_themes');
        can_ok($mod, 'violates');
        can_ok($mod, 'violation');

        my $policy = $mod->new();
        isa_ok($policy, 'Perl::Critic::Policy');
        is($policy->VERSION(), $version_string, "Version of $mod");
    }
}


exit 0;
