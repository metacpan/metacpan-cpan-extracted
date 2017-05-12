use strict;
use warnings;

use File::Spec;
use Test::More;
require Test::Perl::Critic;
 
Test::Perl::Critic->import( 
    -profile => File::Spec->join( 'xt', 'perlcriticrc' ) 
);
all_critic_ok( 'lib', 'examples' );