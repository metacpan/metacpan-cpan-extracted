use 5.006001;

use strict;
use warnings;

use English qw(-no_match_vars);

use PPI::Document;

use Perl::Critic::TestUtils qw(bundled_policy_names);

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '0.002';

#-----------------------------------------------------------------------------

Perl::Critic::TestUtils::block_perlcriticrc();

my @bundled_policy_names = bundled_policy_names();

plan tests => ( 17 * scalar @bundled_policy_names );

# pre-compute for version comparisons
my $version_string = __PACKAGE__->VERSION;

#-----------------------------------------------------------------------------
# Test module interface for each Policy subclass

{
    for my $mod ( @bundled_policy_names ) {

        use_ok($mod) or BAIL_OUT(q<Can't continue.>);
        can_ok($mod, 'applies_to');
        can_ok($mod, 'default_severity');
        can_ok($mod, 'default_themes');
        can_ok($mod, 'get_severity');
        can_ok($mod, 'get_themes');
        can_ok($mod, 'is_enabled');
        can_ok($mod, 'new');
        can_ok($mod, 'set_severity');
        can_ok($mod, 'set_themes');
        can_ok($mod, 'set_themes');
        can_ok($mod, 'violates');
        can_ok($mod, 'violation');
        can_ok($mod, 'is_safe');

        my $policy = $mod->new();
        isa_ok($policy, 'Perl::Critic::Policy');
        is($policy->VERSION(), $version_string, "Version of $mod");
        ok($policy->is_safe(), "CORE policy $mod is marked safe");
    }
}

