#!perl

# Self-compliance tests

use strict;
use warnings;
use English qw( -no_match_vars );
use File::Spec qw();

use Test::More;
use Test::Perl::Critic;

#-----------------------------------------------------------------------------
# Set up PPI caching for speed (used primarily during development)

if ( $ENV{PERL_CRITIC_CACHE} ) {
    require File::Spec;
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

my $rcfile = File::Spec->catfile( qw(xt author 40_perlcriticrc) );
Test::Perl::Critic->import( -severity => 1, -profile => $rcfile );
all_critic_ok();

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
