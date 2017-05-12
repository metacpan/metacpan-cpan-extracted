# $Id: 13_critic.t 102 2009-07-30 14:48:55Z roland $
# $Revision: 102 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/rhonda/trunk/TeX-Hyphen-Pattern/t/13_critic.t $
# $Date: 2009-07-30 16:48:55 +0200 (Thu, 30 Jul 2009) $

use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Perl::Critic; };

if ($EVAL_ERROR) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan( skip_all => $msg );
}

my $rcfile = File::Spec->catfile( 't', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );
all_critic_ok();
