#!perl

use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::Critic::Config ();
use Perl::Critic::UserProfile qw();
use Perl::Critic::PolicyFactory (-test => 1);
use Perl::Critic::PolicyParameter qw{ $NO_DESCRIPTION_AVAILABLE };
use Perl::Critic::Utils qw( policy_short_name );
use Perl::Critic::TestUtils qw(bundled_policy_names);

use Test::More tests => 14;

Perl::Critic::TestUtils::block_perlcriticrc();

#-----------------------------------------------------------------------------
# This script proves that each policy that ships with Perl::Critic overrides
# the supported_parameters() method and, assuming that the policy is
# configurable, that each parameter can parse its own default_string.
#
# This script also verifies that Perl::Critic::PolicyFactory throws an
# exception when we try to create a policy with bogus parameters.  However, it
# is your responsibility to verify that valid parameters actually work as
# expected.  You can do this by using the #parms directive in the *.run files.
#-----------------------------------------------------------------------------

# Figure out how many tests there will be...
my @all_policies = sort ( bundled_policy_names() );

for my $policy ( @all_policies ) {
    test_has_declared_parameters( $policy );
    test_supported_parameters( $policy );
}

#-----------------------------------------------------------------------------

sub test_supported_parameters {
    my $policy_name = shift;
    my @supported_params = $policy_name->supported_parameters();
    my $config = Perl::Critic::Config->new( -profile => 'NONE' );

    for my $param_specification ( @supported_params ) {
        my $parameter =
            Perl::Critic::PolicyParameter->new($param_specification);
        my $param_name = $parameter->get_name();
        my $description = $parameter->get_description();

        ok(
            $description && $description ne $NO_DESCRIPTION_AVAILABLE,
            qq{Param "$param_name" for policy "$policy_name" has a description},
        );

        my %args = (
            -policy => $policy_name,
            -params => {
                 $param_name => $parameter->get_default_string(),
            }
        );
        eval { $config->add_policy( %args ) };
        is(
            $EVAL_ERROR,
            q{},
            qq{Created policy "$policy_name" with param "$param_name"},
        );
    }

    return;
}

#-----------------------------------------------------------------------------

sub test_has_declared_parameters {
    my $policy = shift;
    if ( not $policy->can('supported_parameters') ) {
        fail( qq{I don't know if $policy supports params} );
        diag( qq{This means $policy needs a supported_parameters() method} );
    }
    return;
}

#-----------------------------------------------------------------------------

# ensure we run true if this test is loaded by
# t/14_policy_parameters.t_without_optional_dependencies.t
1;

###############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
