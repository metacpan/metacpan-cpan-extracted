#!perl

# Self-compliance tests

use strict;
use warnings;

use English qw< -no_match_vars >;

use File::Spec qw<>;
use Test::Perl::Critic;

use Test::More;

#-----------------------------------------------------------------------------

if ( !-d '.svn' && !$ENV{TEST_AUTHOR}) {
    ## no critic (RequireInterpolation)
    my $reason = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan skip_all => $reason;
    ## use critic
}

#-----------------------------------------------------------------------------
# Set up PPI caching for speed (used primarily during development)

if ( $ENV{PERL_CRITIC_CACHE} ) {
    require PPI::Cache;
    my $cache_path
        = File::Spec->catdir( File::Spec->tmpdir,
                              'test-perl-critic-cache-'.$ENV{USER} );
    if ( ! -d $cache_path) {
        mkdir $cache_path, oct 700;
    }
    PPI::Cache->import( path => $cache_path );
}

#-----------------------------------------------------------------------------
# Run critic against all of our own files

my $rcfile = File::Spec->catfile( 't', 'perlcriticrc' );
Test::Perl::Critic->import( -severity => 1, -profile => $rcfile );
all_critic_ok();

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
